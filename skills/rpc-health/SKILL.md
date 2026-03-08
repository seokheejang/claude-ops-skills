---
name: rpc-health
description: Blockchain RPC node health checks - block height, sync status, peer count
argument-hint: "<chain-or-endpoint>"
allowed-tools: Bash, Read
---

# RPC Health Check Skill

블록체인 RPC 노드 상태 점검 skill.

## Safety Rules

- read-only JSON-RPC 메서드만 사용
- 트랜잭션 전송이나 상태 변경 절대 금지
- `eth_*` 조회, `net_*`, `web3_*` 메서드만 허용

## Arguments

`$ARGUMENTS` = 체인명 또는 RPC endpoint URL

## Health Checks

### Block Number
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Sync Status
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
```

### Peer Count
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'
```

### Chain ID
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

## Output Format

- hex 값은 10진수로 변환
- 공개 레퍼런스와 블록 높이 비교 (가능한 경우)
- 동기화 상태 명확히 표시 (synced/syncing/behind)
- 에러나 접속 불가 엔드포인트 플래그
