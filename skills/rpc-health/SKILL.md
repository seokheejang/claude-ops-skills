---
name: rpc-health
description: Blockchain RPC node health checks - block height, sync status, peer count
argument-hint: "<chain-or-endpoint>"
allowed-tools: Bash, Read
---

# RPC Health Check Skill

블록체인 RPC 노드 상태 점검 skill.

## Safety: READ-ONLY

read-only JSON-RPC 메서드만 사용. 허용: `eth_*` 조회, `net_*`, `web3_*`.
금지: `eth_sendTransaction`, `eth_sendRawTransaction` 등 쓰기 메서드.

## Arguments

`$ARGUMENTS` = 체인명 또는 RPC endpoint URL. URL이면 직접 사용, 체인명이면 endpoint 확인 요청.

## Workflow

모든 호출: `curl -s -X POST <endpoint> -H "Content-Type: application/json" -d '<payload>'`

| 단계 | method | 확인 사항 |
|------|--------|-----------|
| 연결 | `eth_chainId` | 응답 없으면 **DOWN**, chainId로 네트워크 확인 |
| 동기화 | `eth_syncing` | false=완료, {currentBlock,highestBlock}=진행중(진행률 계산) |
| 블록 높이 | `eth_blockNumber` | hex→10진수 변환, 공개 레퍼런스와 비교 |
| 피어 | `net_peerCount` | 0=네트워크 격리(심각), 소수=Warning |
| 추가 | `eth_getBlockByNumber ["latest",false]`, `eth_gasPrice` | 최신 블록 timestamp 뒤처짐 확인 |

## Health Status 판정

| 상태 | 조건 |
|------|------|
| **HEALTHY** | syncing=false, 블록 차이<5, peers>0 |
| **WARNING** | 블록 차이 5-50 또는 peers<3 |
| **CRITICAL** | 블록 차이>50, syncing=true, peers=0 |
| **DOWN** | 연결 실패, timeout, 에러 응답 |

Multi-endpoint 비교시 테이블(Endpoint/ChainID/BlockHeight/Sync/Peers/Status)로 출력.

## Troubleshooting

- **응답 없음**: TCP 접속 테스트, RPC 포트(8545/8547) 확인, 방화벽/SG
- **동기화 멈춤**: 피어 수 → 0이면 부트노드/네트워크, 디스크 공간, 블록 timestamp
- **블록 높이 차이**: syncing 여부, 하드웨어 IOPS/CPU, 체인별 동기화 시간

## Output

hex→10진수 변환. 레퍼런스 비교. HEALTHY/WARNING/CRITICAL/DOWN 명시. 에러 **굵게**.
