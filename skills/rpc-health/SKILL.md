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
- `eth_sendTransaction`, `eth_sendRawTransaction` 등 쓰기 메서드 절대 금지

## When to Use

- RPC 노드가 정상 동작하는지 확인할 때
- 블록 동기화 상태를 점검할 때
- 여러 노드 간 블록 높이를 비교할 때
- K8s 내부 RPC 엔드포인트를 헬스체크할 때
- 장애 의심 시 빠른 상태 판단이 필요할 때

## Arguments

`$ARGUMENTS` = 체인명 또는 RPC endpoint URL

- URL이면 직접 사용: `http://localhost:8545`, `https://rpc.example.com`
- 체인명이면 사용자에게 endpoint를 확인

## Step-by-Step Workflow

### Step 1: 기본 연결 확인
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```
- 응답이 없으면 → **Down** (연결 불가)
- chainId로 올바른 네트워크인지 확인

### Step 2: 동기화 상태 확인
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
```
- `result: false` → 동기화 완료
- `result: {currentBlock, highestBlock}` → 동기화 중 (진행률 계산)

### Step 3: 블록 높이 확인
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```
- hex 값을 10진수로 변환
- 가능하면 공개 레퍼런스(Etherscan 등)와 비교

### Step 4: 피어 상태 확인
```bash
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'
```
- 0 peers → 네트워크 격리 상태, 심각한 문제
- 피어 수가 매우 적으면 Warning

### Step 5: 추가 점검 (필요시)
```bash
# 최신 블록 타임스탬프 확인 (블록이 오래됐는지)
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}'

# 가스 가격 확인
curl -s -X POST <endpoint> -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}'
```
- 최신 블록 timestamp가 현재 시간보다 크게 뒤처지면 → 동기화 문제

## Health Status 판정 기준

| 상태 | 조건 | 설명 |
|------|------|------|
| **HEALTHY** | syncing=false, 블록 차이 < 5, peers > 0 | 정상 |
| **WARNING** | 블록 차이 5-50 또는 peers < 3 | 약간 뒤처짐/피어 부족 |
| **CRITICAL** | 블록 차이 > 50, syncing=true, peers=0 | 심각한 지연/격리 |
| **DOWN** | 연결 실패, timeout, 에러 응답 | 노드 다운 |

## Multi-endpoint 비교

여러 엔드포인트를 동시에 체크할 때 비교 테이블로 출력:

```
| Endpoint       | Chain ID | Block Height | Sync   | Peers | Status   |
|----------------|----------|-------------|--------|-------|----------|
| node-1:8545    | 42161    | 298,123,456 | synced | 25    | HEALTHY  |
| node-2:8545    | 42161    | 298,123,400 | synced | 12    | WARNING  |
| node-3:8545    | 42161    | -           | -      | -     | DOWN     |
```

## Troubleshooting

### 노드 응답 없음
1. 네트워크 연결 확인 (curl로 TCP 레벨 접속 테스트)
2. RPC 포트가 올바른지 확인 (8545, 8547 등)
3. 방화벽/SecurityGroup 확인

### 동기화가 멈춤
1. 피어 수 확인 — 0이면 부트노드/네트워크 설정 문제
2. 디스크 공간 확인 — 풀이면 동기화 중단
3. 최신 블록 timestamp 확인 — 얼마나 뒤처졌는지

### 블록 높이 차이가 큼
1. 노드가 syncing 중인지 확인
2. 하드웨어 성능 (IOPS, CPU) 확인
3. 체인별 동기화 소요 시간 고려

## Output Format

- hex 값은 10진수로 변환하여 표시
- 공개 레퍼런스와 블록 높이 비교 (가능한 경우)
- 동기화 상태 명확히 표시 (synced/syncing/behind)
- 에러나 접속 불가 엔드포인트는 **굵게** 표시
- 판정 결과를 HEALTHY/WARNING/CRITICAL/DOWN으로 명시
