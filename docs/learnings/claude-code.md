# Claude Code Learnings

Claude Code CLI 자체의 동작, 함정, 운영 패턴 관련 학습 기록. 시간순 append.

---

## 2026-04-17 — Slash command invocation은 세션 시작 시점의 SKILL.md 캐시본을 주입한다

**Category**: tooling
**Related**: `skills/*/SKILL.md`, `scripts/install.sh` (심링크 생성)

### 컨텍스트

`skills/db-ops/SKILL.md`를 수정한 후 **같은 Claude Code 세션**에서 `/db-ops`를 호출하니, slash command invocation에 붙어온 SKILL.md 본문이 **수정 이전 버전**이었다. `~/.claude/skills/db-ops`는 repo의 SKILL.md를 가리키는 심링크이고, `Read` tool로 직접 읽으면 최신 내용이 나오는데도 `/db-ops` invocation context는 옛 버전.

### 내용

- Claude Code CLI는 세션 시작 시 `~/.claude/skills/` 하위를 스캔하여 각 SKILL.md 내용을 **캐시**한다
- slash command invocation(`/skill-name`)은 이 캐시본을 모델 컨텍스트에 주입 — 파일 시스템을 재조회하지 않음
- 심링크여도 동일: 심링크 resolution 자체는 즉시 반영되지만, 캐시된 내용이 먼저 사용됨
- 확인 방법: 같은 세션에서 SKILL.md 수정 → `/<skill>` 호출 시 붙는 text vs `Read ~/.claude/skills/<skill>/SKILL.md` 결과 비교. 두 개가 다르면 캐시 이슈

### 왜 중요한가

- **SKILL.md 수정 → 같은 세션에서 테스트** 워크플로우는 작동 안 함. 수정 효과가 안 보여서 "분명 수정했는데 왜?" 로 디버깅 시간 낭비
- **올바른 테스트 사이클**: 수정 → Claude Code 재시작 → `/skill` 호출
- 자동화 반복 루프(e.g., `/ralph`로 skill 자체를 튜닝하는 경우)에서는 세션 재시작을 흐름에 포함시켜야 함
- 회피책으로 `Read` tool로 최신 SKILL.md를 직접 참조하면서 dry-run 시뮬레이션은 가능하지만, 실제 skill 실행은 불가

---

## 2026-05-08 — SKILL.md 100줄 룰 분할 시 토픽 수에 따라 구조 결정

**Category**: convention
**Related**: `skills/write-a-skill/REFERENCE.md`, `skills/mmdraw/`, `skills/compound/`, `skills/best-practice/`, `skills/ralph/`

### 컨텍스트

write-a-skill의 100줄 SKILL.md 룰을 적용해 4개 스킬을 분할했다 (mmdraw 267→97, compound 247→97, best-practice 167→86, ralph 121→96). 분할 단위 결정 기준이 매번 다르게 적용되는 게 일관성 떨어져 보였는데, 사실 **토픽 수와 결정론성**으로 자연스럽게 갈라진다.

### 내용

분할 단위 결정 트리:

```
SKILL.md > 100줄
├─ 분리 토픽 1~2개 → REFERENCE.md (단일 파일)
│   └─ 예: mmdraw (Flowchart + Sequence 문법)
├─ 분리 토픽 3개+ → references/ 디렉토리
│   ├─ 예: compound (work-doc, learnings, changelog)
│   ├─ 예: best-practice (sources, verification, output)
│   └─ 예: ralph (checklists, policy)
└─ 결정론적 작업 (검증/렌더링/파싱) → scripts/
    └─ 예: mmdraw/scripts/render.sh (mmdc 우선, npx fallback)
```

추가 단위:
- `assets/` — YAML/JSON 템플릿, 정적 자원 (현재까지 사용 사례 없음)

### 왜 중요한가

- 다음에 분할 작업할 때 *"이건 단일 REFERENCE.md? 아니면 디렉토리?"* 고민 안 해도 됨
- **압축 트레이드오프 인지**: 100줄 맞추려고 표 → 단락으로 압축하면 가독성 손실. 사람이 빠르게 스캔하기엔 표가 더 좋음. 모델은 동일하게 읽지만 사람 검토 시 불리
- **자기 모순 방지**: write-a-skill 자신이 100줄 룰 위반하면 안 됨 (143줄 → 89줄로 분할). 메타 스킬도 솔선수범 필요

---

## 2026-05-08 — 자기 검증 도구는 단일 도구로 모든 영역을 커버하면 안 된다 (다층 매핑)

**Category**: architecture
**Related**: `skills/ralph/`, `skills/grill-me/`, `~/.claude/plugins/.../code-simplifier`, `~/.claude/plugins/.../code-reviewer`

### 컨텍스트

ralph가 *"코드 누락, 컨벤션, 코드간 매핑은 잘 잡지만 구조/추상화/효율성 피드백은 못 받는다"*는 사용자 관찰에서 출발. ralph 한계인지 설정 한계인지 진단하는 과정에서 LLM 활용 코드 검토는 **본질적으로 다층 구조**라는 게 드러났다.

### 내용

코드 검토 4단계 영역과 도구 매핑:

| 레벨 | 영역 | 도구 |
|------|------|------|
| L1 | 라인 (lint, syntax, 보안 패턴) | linter, pre-commit hook |
| L2 | 함수/파일 (동작, 엣지케이스, 컨벤션) | ralph (이번 저장소 기준) |
| L3 (단순화) | 중복 통합, 명확성 개선 | code-simplifier agent (Anthropic plugin) |
| L3 (품질) | bugs, logic errors, security, code quality | code-reviewer agent (Anthropic plugin / 자체 customize) |
| L4 (설계) | 추상화, 모듈 경계, 트레이드오프 | grill-me + 사람 |
| L4 (아키텍처) | 시스템 구조, 미래 부담 | 사람 리뷰, ADR/RFC |

ralph FAIL 판정 기준 *"이거 안 고치면 실제로 터지나"*는 L2 적합. L3 이상 이슈(*"이 추상화가 잘못됐다"*)는 즉시 안 터지므로 ralph가 영원히 NOTE에 둠 — **이건 ralph 결함이 아니라 의도된 영역 분리**.

### 왜 중요한가

- 한 도구에 모든 영역 욱여넣으면 초점 흐려짐. 너의 본능적 직관(*"ralph가 거기까지 못 하나"*)이 정확
- **페어링 안내가 핵심**: 사용자가 *"여기까지가 ralph 한계, 다음은 X"* 알면 자연스럽게 후속 도구 호출
- L4 아키텍처는 LLM이 판단하기 어려운 영역 (도메인 지식, 미래 예측 필요). 솔직하게 *"사람"*으로 위임
- Anthropic 공식 plugin의 `code-simplifier`, `code-reviewer` agent를 그대로 쓰기보다 **베이스로 가져와서 우리 컨벤션에 맞춰 customize**하는 게 검증 부담 줄임 (옵션 C)
- *"제대로 동작할지 모르는 도구를 그대로 신뢰"*보다 *"검증된 출발점 + 우리 환경 맞춤"*이 더 자신 있게 쓸 수 있음

