#!/usr/bin/env python3
"""Cosmos RPC - Total TX counter via batch /blockchain calls.

Usage:
    python3 cosmos_total_tx.py <RPC_URL>
    python3 cosmos_total_tx.py http://localhost:26657
    python3 cosmos_total_tx.py http://localhost:26657 --from 1000 --to 2000
"""

import json
import urllib.request
import time
import sys
import argparse

BATCH_SIZE = 200       # 200 RPC calls per HTTP request (tested safe limit, 250+ silently fails)
BLOCK_RANGE = 20       # CometBFT hardcoded maxBlockchainQueryRange
BLOCKS_PER_REQ = BATCH_SIZE * BLOCK_RANGE  # 4,000 blocks per HTTP request


def get_latest_height(rpc):
    req = urllib.request.Request(f"{rpc}/status")
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.load(resp)
    return int(data["result"]["sync_info"]["latest_block_height"])


def batch_request(rpc, calls):
    payload = json.dumps(calls).encode()
    req = urllib.request.Request(
        rpc,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())


def main():
    parser = argparse.ArgumentParser(description="Cosmos total TX counter")
    parser.add_argument("rpc", help="RPC endpoint URL")
    parser.add_argument("--from-block", type=int, default=1, dest="from_block")
    parser.add_argument("--to-block", type=int, default=0, dest="to_block",
                        help="0 = latest")
    args = parser.parse_args()

    rpc = args.rpc.rstrip("/")
    latest = get_latest_height(rpc)
    start_block = args.from_block
    end_block = args.to_block if args.to_block > 0 else latest

    total_range = end_block - start_block + 1
    total_requests = (total_range + BLOCKS_PER_REQ - 1) // BLOCKS_PER_REQ
    print(f"Latest block: {latest:,}")
    print(f"Range: {start_block:,} ~ {end_block:,} ({total_range:,} blocks)")
    print(f"Strategy: batch {BATCH_SIZE} x {BLOCK_RANGE} = {BLOCKS_PER_REQ:,} blocks/req")
    print(f"Total HTTP requests: {total_requests:,}")
    print("=" * 60)

    total_tx = 0
    blocks_processed = 0
    start_time = time.time()
    cursor = start_block
    req_count = 0
    retries = 0

    while cursor <= end_block:
        calls = []
        for i in range(BATCH_SIZE):
            min_h = cursor + i * BLOCK_RANGE
            max_h = min(min_h + BLOCK_RANGE - 1, end_block)
            if min_h > end_block:
                break
            calls.append({
                "jsonrpc": "2.0",
                "id": i,
                "method": "blockchain",
                "params": {"minHeight": str(min_h), "maxHeight": str(max_h)},
            })

        if not calls:
            break

        try:
            results = batch_request(rpc, calls)
            if not isinstance(results, list):
                results = [results]
        except Exception as e:
            retries += 1
            if retries > 5:
                print(f"\n[FATAL] Too many retries at block {cursor}: {e}")
                break
            print(f"\n[WARN] Retry {retries} at block {cursor}: {e}")
            time.sleep(2)
            continue

        retries = 0
        batch_tx = 0
        batch_blocks = 0
        for r in results:
            if isinstance(r, dict) and "result" in r:
                for m in r["result"].get("block_metas", []):
                    batch_tx += int(m.get("num_txs", 0))
                    batch_blocks += 1

        total_tx += batch_tx
        blocks_processed += batch_blocks
        req_count += 1
        cursor += len(calls) * BLOCK_RANGE

        elapsed = time.time() - start_time
        pct = blocks_processed / total_range * 100
        rate = blocks_processed / elapsed if elapsed > 0 else 0
        eta = (total_range - blocks_processed) / rate if rate > 0 else 0

        sys.stderr.write(
            f"\r[{pct:5.1f}%] {blocks_processed:>10,}/{total_range:,} blk | "
            f"tx={total_tx:>10,} | "
            f"req {req_count}/{total_requests} | "
            f"{rate:,.0f} blk/s | ETA {eta:.0f}s   "
        )
        sys.stderr.flush()

    elapsed = time.time() - start_time
    print(file=sys.stderr)
    print("=" * 60)
    print(f"  Total blocks : {blocks_processed:,}")
    print(f"  Total TX     : {total_tx:,}")
    print(f"  Elapsed      : {elapsed:.1f}s ({elapsed/60:.1f}m)")
    if blocks_processed:
        print(f"  Avg TX/block : {total_tx / blocks_processed:.4f}")


if __name__ == "__main__":
    main()
