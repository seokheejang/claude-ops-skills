---
name: compound
description: 작업 종합 - 학습 기록, 작업 문서 정리, CHANGELOG 업데이트, 지식 축적. 작업 완료/중단 시 호출.
argument-hint: "[completed|paused] <작업 설명>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Compound - 작업 종합

작업 완료/중단 시점에 호출. 수행한 작업을 정리하고 학습을 축적해 **다음 사이클을 더 쉽게** 만든다 (Compound Engineering, Every Inc 2025). 상세 템플릿은 [references/](references/) 참조.

## Arguments

`$ARGUMENTS` 파싱:
- 첫 토큰이 `completed` 또는 `paused`면 상태 지정, 나머지는 작업 설명
- 상태 키워드 없으면 대화 컨텍스트에서 자동 감지
- 예: `/compound completed mmdraw 스킬 추가`, `/compound paused`, `/compound`

## Reference Guide

각 단계 상세는 토픽별 reference로 위임. 작업 컨텍스트에 따라 해당 파일을 로드.

| Topic | File | Load When |
|-------|------|-----------|
| 작업 문서 (template, 갱신 규칙, 번호 채번) | [references/work-doc.md](references/work-doc.md) | 3단계 (A) — `0X-*.md` 작성/갱신 |
| 학습 기록 (append-first, 파일 구조, 분리/마이그레이션) | [references/learnings.md](references/learnings.md) | 3단계 (B) — `docs/learnings/` 갱신 |
| CHANGELOG (template, 버전 규칙) | [references/changelog.md](references/changelog.md) | 3단계 (C) — `docs/CHANGELOG.md` 갱신 (completed 한정) |

## Workflow

### 1단계: Context Scan

스캔 대상: `docs/CHANGELOG.md` (최신 버전/백로그), `docs/[0-9][0-9]-*.md` (활성 작업 문서), `docs/archive/[0-9][0-9]-*.md` (완료 문서 + 번호 채번), `docs/learnings/*.md` (기존 학습, 중복 방지), 현재 대화 컨텍스트 (수행한 작업, 변경 파일, 발견 사항).

### 2단계: 분류 & 결정

**상태 판단:**

| 상태 | 조건 | 처리 |
|------|------|------|
| `completed` | 인자에 명시 또는 "완료/done" 감지 | 작업 문서 → archive 이동 |
| `paused` | 인자에 명시 또는 "중단/나중에" 감지 | 핸드오프 섹션 포함, 최상위 유지 |

**문서 결정:**

```
활성 작업 문서(0X-*.md)가 docs/ 최상위에 있는가?
├─ YES: 현재 작업이 그 문서의 토픽과 관련?
│  ├─ YES → 기존 문서 업데이트 (날짜별 섹션 추가)
│  └─ NO  → 다음 번호로 신규 생성
└─ NO: 다음 번호로 신규 생성
```

번호 채번 규칙은 [references/work-doc.md](references/work-doc.md) 참조.

### 3단계: 문서 작성

순서대로 처리. 각 항목 상세는 위 Reference Guide 참조.

- **(A) 작업 문서** — 신규 작성 또는 기존 갱신 → [work-doc.md](references/work-doc.md)
- **(B) 학습 기록** — 비자명 인사이트만 추출, append-first 정책 → [learnings.md](references/learnings.md)
- **(C) CHANGELOG** — `completed` 한정, 새 minor 버전 추가 → [changelog.md](references/changelog.md)

### 4단계: 정리 & Discoverability

#### Archive 이동 (completed만)

```bash
mkdir -p docs/archive
mv docs/0X-<name>.md docs/archive/0X-<name>.md
```

CHANGELOG.md 내 해당 문서 링크를 `archive/` 경로로 수정한다.

#### Discoverability Check

프로젝트의 `CLAUDE.md`에 `docs/learnings/` 경로가 언급되어 있는지 확인. 없으면 **제안**만 (강제 적용 X). 제안 텍스트 템플릿은 [references/learnings.md](references/learnings.md) 하단 참조.

## 출력 포맷

```
=== Compound Summary ===
상태: completed | paused
작업 문서: docs/0X-<name>.md [→ docs/archive/]
학습 기록: docs/learnings/<domain>.md (append|신규|없음)
CHANGELOG: vX.Y 추가 | 업데이트 없음
다음 세션: backlog 확인 | 핸드오프 참조
```

선택적 경고: `⚠ <file>.md splitting recommended` (600줄/15섹션 초과), `⚠ <prefix>-*.md N개 → <prefix>.md 통합 제안` (마이그레이션 필요 시).

## 안전 규칙

- `docs/CHANGELOG.md`, `*-authoring.md`, `docs/diagrams/` 기존 내용 삭제/이동 금지 (append-only)
- 학습 기록은 **append-first** (정책 상세: [learnings.md](references/learnings.md))
- 학습 파일 자동 분리 금지 (링크 깨짐 위험 — 사용자 승인 필수)
- Archive 이동 전 CHANGELOG 링크를 먼저 업데이트
