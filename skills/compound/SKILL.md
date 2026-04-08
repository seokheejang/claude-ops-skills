---
name: compound
description: 작업 종합 - 학습 기록, 작업 문서 정리, CHANGELOG 업데이트, 지식 축적. 작업 완료/중단 시 호출.
argument-hint: "[completed|paused] <작업 설명>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Compound - 작업 종합

Compound Engineering(Every Inc, 2025)의 핵심 개념을 적용한 작업 종합 스킬.
**작업 완료 또는 중단 시점에 호출**하여 수행한 작업을 정리하고, 학습을 축적한다.

핵심 원칙: 매 작업 사이클이 **다음 사이클을 더 쉽게** 만들어야 한다.
단순히 "무엇을 했는가"를 기록하는 것이 아니라, "무엇을 배웠는가"를 축적한다.

## Arguments

`$ARGUMENTS` 파싱:
- 첫 토큰이 `completed` 또는 `paused`면 상태 지정, 나머지는 작업 설명
- 상태 키워드 없으면 대화 컨텍스트에서 자동 감지
- 예: `/compound completed mmdraw 스킬 추가`, `/compound paused`, `/compound`

---

## Workflow

### 1단계: Context Scan

아래 순서로 현재 상태를 파악한다.

| 대상 | 목적 |
|------|------|
| `docs/CHANGELOG.md` | 최신 버전, 백로그 파악 |
| `docs/[0-9][0-9]-*.md` | 활성 작업 문서 확인 |
| `docs/archive/[0-9][0-9]-*.md` | 완료된 문서 + 번호 채번용 |
| `docs/learnings/*.md` | 기존 학습 기록 (중복 방지) |
| 현재 대화 컨텍스트 | 수행한 작업, 변경 파일, 발견 사항 |

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

**번호 채번:**
- `docs/` + `docs/archive/` 양쪽에서 `[0-9][0-9]-` 접두사의 최대값 N을 찾는다
- 신규 문서는 `{N+1:02d}-<slug>.md`

### 3단계: 문서 작성

3가지를 순서대로 처리한다.

#### (A) 작업 문서

기존 `0X-*.md` 패턴을 따른다. 신규 생성 시 아래 템플릿 사용:

```markdown
# <Task Title>

**날짜**: YYYY-MM-DD
**상태**: 진행중 | 일시중단 | 완료

## 배경

<왜 이 작업이 필요했는가. 동기, 요청 사항.>

## 변경 내용

<무엇을 했는가. 파일별, 기능별 정리.>

| 파일/디렉토리 | 변경 | 설명 |
|---------------|------|------|
| `path/to/file` | 신규/수정/삭제 | 간단 설명 |

## 결과

<성과, 테스트 결과, 관찰 사항.>

## 핸드오프

<paused: 다음 세션에서 바로 이어갈 수 있는 구체적 컨텍스트>
<completed: "→ CHANGELOG.md에 기록됨" 또는 생략>
```

기존 문서 업데이트 시: 날짜 헤더(`### YYYY-MM-DD 추가 작업`)로 섹션을 추가한다. 기존 내용은 수정하지 않는다.

#### (B) 학습 기록 추출

작업 중 발견한 **비자명(non-obvious)한 인사이트**가 있으면 `docs/learnings/`에 기록한다.

**기록 대상 (persist):**
- 삽질 후 발견한 해결법 (에러 원인 + 해결 과정)
- 도구/라이브러리의 문서화되지 않은 한계
- 비직관적인 패턴이나 규칙
- 의사결정 근거 (왜 A를 선택하고 B를 버렸는가)
- 반복될 수 있는 실수와 예방법

**스킵 대상 (discard):**
- 단순 설정 변경 (config 값 수정)
- 코드에서 바로 읽히는 자명한 내용
- 일회성 작업 (다시 발생하지 않을 것)
- 이미 `docs/learnings/`에 유사 내용이 있는 것

학습 기록 템플릿:

```markdown
---
title: <학습 제목>
date: YYYY-MM-DD
category: <syntax|architecture|tooling|debugging|convention>
related: <관련 파일, 스킬, 도구>
---

## 컨텍스트

<어떤 상황에서 이걸 발견했는가>

## 내용

<핵심 학습. 구체적으로, 코드/명령어 예시 포함.>

## 왜 중요한가

<다음에 비슷한 상황에서 어떻게 도움이 되는가>
```

파일명: `<slug>.md` (예: `mermaid-syntax-gotchas.md`, `excalidraw-json-limitations.md`)

기존 `docs/learnings/`에 같은 토픽의 문서가 있으면:
- 내용이 보완적이면 → 기존 문서에 섹션 추가
- 완전히 다른 측면이면 → 신규 생성

#### (C) CHANGELOG 업데이트

**completed일 때만** `docs/CHANGELOG.md`에 새 버전 항목을 추가한다.

```markdown
### vX.Y -- <Title> (YYYY-MM-DD)

- [0N-<name>.md](archive/0N-<name>.md) 작업 문서
- <변경 요약 bullet point>
- <변경 요약 bullet point>
```

버전 번호: 기존 최신 버전에서 minor +1 (예: v0.5 → v0.6)

### 4단계: 정리 & Discoverability

#### Archive 이동 (completed만)

```bash
mkdir -p docs/archive
mv docs/0X-<name>.md docs/archive/0X-<name>.md
```

CHANGELOG.md 내 해당 문서 링크를 `archive/` 경로로 수정한다.

#### Discoverability Check

프로젝트의 `CLAUDE.md`를 읽고, `docs/learnings/` 경로가 언급되어 있는지 확인한다.

- 이미 있음 → 스킵
- 없음 → 아래와 같은 최소한의 추가를 **제안**한다 (강제 적용하지 않음):

```markdown
## Learnings

작업 중 발견한 패턴, 해결법, 의사결정 근거는 `docs/learnings/`에 축적됨.
새 작업 시작 전 관련 학습 기록이 있는지 확인하면 삽질을 줄일 수 있음.
```

---

## 출력 포맷

```
=== Compound Summary ===

상태: completed | paused
작업 문서: docs/0X-<name>.md [→ docs/archive/ 이동됨]
학습 기록: docs/learnings/<name>.md (신규|업데이트|없음)
CHANGELOG: vX.Y 항목 추가됨 | 업데이트 없음

다음 세션: backlog 확인 | 핸드오프 참조
→ https://mermaid-to-excalidraw.vercel.app/ (다이어그램 변환 필요 시)
```

---

## 안전 규칙

- `docs/CHANGELOG.md` 기존 내용 삭제 금지 (append-only)
- `*-authoring.md` 도구 가이드를 이동/수정하지 않음
- `docs/diagrams/` 디렉토리를 건드리지 않음
- 학습 기록은 덮어쓰기보다 신규 생성 우선
- Archive 이동 전 반드시 CHANGELOG 링크를 먼저 업데이트
