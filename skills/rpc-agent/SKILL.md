---
name: rpc-agent
description: Blockchain RPC analytics agent - block traversal, tx counting, on-chain data aggregation
argument-hint: "<endpoint> <module> [options]"
allowed-tools: Bash, Read, Grep, Glob, Skill
---

# RPC Agent Skill

블록체인 RPC 분석 에이전트 진입점. 단일 RPC 호출로 얻을 수 없는 데이터를 다단계 조회·집계한다.

## CRITICAL SAFETY

- **read-only 메서드만 사용** (상세 규칙: `agents/rpc-analytics.md` → CRITICAL SAFETY 참조)
- 트랜잭션 전송·서명·상태 변경 절대 금지

## Arguments

`$ARGUMENTS` 형식:

```
/rpc-agent <endpoint> <module> [options]
```

- `<endpoint>`: RPC URL (예: `http://localhost:8545`, `https://rpc.example.com`)
- `<module>`: 분석 모듈명
- `[options]`: 모듈별 추가 파라미터

### 사용 예시

```
/rpc-agent http://localhost:8545 block-tx-count --last 100
/rpc-agent http://localhost:8545 block-tx-count --from 19500000 --to 19500100
/rpc-agent http://localhost:8545 gas-analysis --last 200
/rpc-agent http://localhost:8545 block-time-analysis --last 500
/rpc-agent http://localhost:26657 block-time-analysis --last 1000
```

## Available Modules

| Module | 설명 | 지원 체인 | 상태 |
|--------|------|-----------|------|
| `block-tx-count` | 블록 범위 트랜잭션 수 집계 | EVM, Cosmos | 사용 가능 |
| `gas-analysis` | gasUsed / utilization / baseFee 추이 | EVM only | 사용 가능 |
| `block-time-analysis` | 블록 생성 간격 통계 + 이상치 | EVM, Cosmos | 사용 가능 |
| `address-activity` | 주소별 활동 분석 | — | 스펙 보류 (인덱서 권장) |

## Workflow

이 skill은 `agents/rpc-analytics.md`의 워크플로우를 실행한다.

### Step 1: Arguments 파싱

`$ARGUMENTS`에서 endpoint, module, options를 추출.

- endpoint가 없으면 → 사용자에게 URL 요청
- module이 없으면 → Available Modules 목록을 보여주고 선택 요청
- options가 없으면 → 기본값 사용 (최근 50블록)

### Step 2: Agent 프로토콜 실행

`agents/rpc-analytics.md`를 참조하여 아래 순서로 실행:

1. **Preflight**: `/rpc-health <endpoint>`로 노드 상태 확인
2. **Parameter Resolution**: 블록 범위 결정
   - `--last N`: 최근 N블록 (기본: 50, 최대: 1000)
   - `--from X --to Y`: 명시적 블록 범위
   - 미지정: 최근 50블록
3. **Module Execution**: 선택된 모듈의 분석 워크플로우 수행
4. **Report Generation**: 결과 테이블 출력

### Step 3: 결과 보고

Agent의 Report Format에 따라 결과를 출력한다.
에러나 스킵된 블록이 있으면 명시적으로 보고.

## Bundled Scripts

이 skill 디렉토리에 포함된 스크립트 (`scripts/` 하위):

| Script | 용도 |
|--------|------|
| `cosmos_total_tx.py` | Cosmos 체인 전체 블록 TX 수 집계 (배치 순회) |

실행 예시:
```bash
python3 skills/rpc-agent/scripts/cosmos_total_tx.py http://localhost:26657
```

## Error Handling

- endpoint 연결 실패 → `/rpc-health` 결과와 함께 원인 안내
- module명 오타 → 사용 가능한 모듈 목록 다시 표시
- 블록 범위 초과 (>1000) → 축소 또는 분할 제안
- RPC rate limit (429) → 배치 크기 축소 후 재시도
