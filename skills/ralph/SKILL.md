---
name: ralph
description: Self-review loop - iteratively verify and fix work until quality criteria are met
argument-hint: "[max-iterations] <task-description>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

# Ralph - Self-Review Loop

작업 수행 후 스스로 검증하고, 이슈 발견 시 수정 → 재검증을 반복. `/ralph` 호출 시에만 동작. 상세 체크리스트와 판정 정책은 [references/](references/) 참조.

## Arguments

`$ARGUMENTS` 파싱 규칙:

1. 첫 토큰이 숫자(1~20)면 **max-iterations** (기본: 5)
2. 나머지 텍스트가 **작업 설명**
3. 작업 설명이 없으면 직전 사용자 요청과 그에 대한 Claude 응답(마지막 1턴)에서 작업을 이어받음

예시:
- `/ralph settings.json 보안 검토` → 5회 반복
- `/ralph 3 deny 규칙 누락 검사` → 3회 반복
- `/ralph 방금 작업 재검증` → 직전 작업 검증

## Reference Guide

| Topic | File | Load When |
|-------|------|-----------|
| 도메인별 체크리스트 (코드/DevOps/문서/범용) | [references/checklists.md](references/checklists.md) | Phase 2 — 작업 도메인 감지 후 해당 체크리스트만 로드 |
| FAIL/NOTE 판정 + Collaborative 원칙 | [references/policy.md](references/policy.md) | Phase 3 — 매 라운드 판정 시 |

## Execution Protocol

### Phase 1: 작업 수행

작업 설명을 분석하고 실행한다. 이미 완료된 작업의 재검증인 경우 이 단계를 건너뛴다.

### Phase 2: 도메인 감지 및 체크리스트 선택

작업 내용에 따라 [references/checklists.md](references/checklists.md)에서 해당 도메인의 체크리스트만 로드. 도메인 감지 신호는 그 파일 상단 표 참조. 복수 해당 시 모두 적용.

### Phase 3: 반복 검증 루프

각 라운드마다 다음 포맷으로 출력:

```
=== Ralph Review #N/M ===

검증 결과:
- [PASS] 항목: 설명
- [FAIL] 항목: 이슈 내용 → 수정 방안 (실행 시 터지는 것만)
- [NOTE] 항목: 개선 제안 (터지지 않지만 참고, 수정 안 함)

수정 사항: (있을 경우)
- 파일명:라인 — 변경 내용

판정: CONTINUE (이슈 있음) / COMPLETE (전체 통과)
```

**루프 규칙:**
- [FAIL] 항목 발견 → 즉시 수정 → 다음 라운드에서 재검증
- [NOTE] 항목 → 수정하지 않음. 리포트에만 표기
- 이전 라운드에서 [PASS]한 항목은 재검증 스킵 (토큰 절약)
- 2회 연속 동일 [FAIL] → 사용자 판단 요청 (상세: [policy.md](references/policy.md))
- 전체 [PASS] → 남은 라운드 스킵하고 즉시 완료

### Phase 4: 최종 리포트

```
=== Ralph Complete (N rounds) ===
요약: 총 N/M 라운드, 발견 X건, 수정 Y건, 미해결 Z건
변경 파일:
- file1.md — 변경 요약
- file2.json — 변경 요약
```

## Token Efficiency Rules

1. **조기 종료**: 첫 라운드 통과 시 즉시 완료
2. **증분 검증**: 이전 [PASS] 항목은 재검사 스킵
3. **간결한 출력**: 변경점 중심, 반복 OK 메시지 최소화
4. **빈 루프 방지**: 수정할 것 없으면 루프 중단
5. **부분 로드**: 매칭된 도메인 체크리스트만 로드

## Scope and Pairing

ralph는 **L1+L2 (라인/함수 동작 검증)**에 특화. 다음 영역은 ralph 범위 밖이므로 별도 도구로 후속 검토:

| 검토 영역 | 도구 |
|----------|------|
| 코드 단순화/중복 통합 | code-simplifier agent (Anthropic plugin) |
| 버그/로직/보안/품질 (L3) | code-reviewer agent (도입 예정 — `agents/code-reviewer.md`) |
| 설계 결정/트레이드오프 검토 (L4) | `/grill-me` |
| 아키텍처 결정 | 사람 리뷰, ADR 작성 |

ralph가 [NOTE]로 보고한 항목 중 구조적 이슈는 위 도구로 후속 검토 권장.
