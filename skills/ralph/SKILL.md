---
name: ralph
description: Self-review loop - iteratively verify and fix work until quality criteria are met
argument-hint: "[max-iterations] <task-description>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

# Ralph - Self-Review Loop

작업 수행 후 스스로 검증하고, 이슈 발견 시 수정 → 재검증을 반복하는 자기 검증 루프.
사용자가 `/ralph`를 호출할 때만 동작하며, 일반 대화에는 영향 없음.

## Arguments

`$ARGUMENTS` 파싱 규칙:

1. 첫 토큰이 숫자(1~20)면 **max-iterations** (기본: 5)
2. 나머지 텍스트가 **작업 설명**
3. 작업 설명이 없으면 직전 대화 컨텍스트에서 작업을 이어받음

예시:
- `/ralph settings.json 보안 검토` → 5회 반복, settings.json 보안 검토
- `/ralph 3 deny 규칙 누락 검사` → 3회 반복
- `/ralph 방금 작업 재검증` → 5회 반복, 직전 작업 검증

## Execution Protocol

### Phase 1: 작업 수행

작업 설명을 분석하고 실행한다. 이미 완료된 작업의 재검증인 경우 이 단계를 건너뛴다.

### Phase 2: 도메인 감지 및 체크리스트 선택

작업 내용에 따라 적절한 검증 체크리스트를 자동 선택:

**코드 작성/수정:**
- [ ] 문법 에러 없음 (lint/build 통과)
- [ ] 보안 취약점 없음 (injection, hardcoded secrets, XSS)
- [ ] 엣지 케이스 처리됨
- [ ] 기존 코드와 일관된 스타일
- [ ] 불필요한 코드 없음 (over-engineering 방지)

**DevOps/IaC (K8s, Helm, Terraform, ArgoCD):**
- [ ] READ-ONLY 안전 규칙 준수 (mutating 명령어 없음)
- [ ] settings.json deny 규칙과 SKILL.md 금지 목록 일치
- [ ] 하드코딩된 시크릿/경로/IP 없음
- [ ] 권한이 최소 범위로 제한됨
- [ ] 예시 값이 제네릭명 사용 (my-cluster, my-app 등)

**설정/문서:**
- [ ] 다른 파일과 일관성 유지
- [ ] 누락 항목 없음
- [ ] 오타/포맷 오류 없음
- [ ] 마크다운 테이블/링크 정상

**범용 (위에 해당 없을 때):**
- [ ] 사용자 요구사항 완전히 충족
- [ ] 결과물이 정확하고 완성됨
- [ ] 불필요한 부작용 없음

### Phase 3: 반복 검증 루프

각 라운드마다 다음 포맷으로 출력:

```
=== Ralph Review #N/M ===

검증 결과:
- [PASS] 항목: 설명
- [FAIL] 항목: 이슈 내용 → 수정 방안

수정 사항: (있을 경우)
- 파일명:라인 — 변경 내용

판정: CONTINUE (이슈 있음) / COMPLETE (전체 통과)
```

**루프 규칙:**
- [FAIL] 항목 발견 → 즉시 수정 → 다음 라운드에서 재검증
- 이전 라운드에서 [PASS]한 항목은 재검증 스킵 (토큰 절약)
- 수정 없이 동일한 [FAIL]이 반복되면 → 사용자에게 판단 요청
- 전체 [PASS] → 남은 라운드 스킵하고 즉시 완료

### Phase 4: 최종 리포트

```
=== Ralph Complete (N rounds) ===

요약:
- 총 라운드: N/M
- 발견 이슈: X건
- 수정 완료: Y건
- 미해결: Z건 (있을 경우 상세 목록)

변경 파일:
- file1.md — 변경 내용 요약
- file2.json — 변경 내용 요약
```

## Token Efficiency Rules

이 스킬은 토큰 예산이 제한된 환경을 고려하여 설계됨:

1. **조기 종료**: 첫 라운드에서 이슈 없으면 즉시 완료 (1회로 끝남)
2. **증분 검증**: 이전에 통과한 항목은 재검사하지 않음
3. **간결한 출력**: 변경점 중심, 반복적인 OK 메시지 최소화
4. **빈 루프 방지**: 수정할 것이 없으면 루프 중단

## Collaborative Behavior

Ralph는 일방적으로 수정하지 않고, 사용자와 함께 찾는다:

- 확실한 이슈 (문법 에러, 보안 취약점) → 즉시 수정
- 판단이 필요한 이슈 (설계 결정, 트레이드오프) → 사용자에게 선택지 제시
- 불확실한 이슈 → "이건 의도된 건가요?" 형태로 질문
- 매 라운드 결과를 공유하며 사용자가 중간에 중단할 수 있음을 안내
