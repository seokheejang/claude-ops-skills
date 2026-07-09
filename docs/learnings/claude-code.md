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

---

## 2026-06-26 — 외부 스킬은 "베끼기 vs plugin 소비 vs submodule" 세 갈래로 결정한다

**Category**: convention
**Related**: `_disabled/humanize-ko/`, `scripts/install.sh`, 외부 repo `epoko77-ai/im-not-ai` (MIT)

### 컨텍스트

외부 Claude Code 스킬(`im-not-ai`의 `humanize-korean`)을 내 스킬셋에 넣으려다, *"직접 베껴 만들면 원본이 업데이트돼도 안 따라온다"*는 한계를 만났다. 실제로 경량판 `humanize-ko`를 직접 만들었으나, 원본이 71패턴/390예시 규모인 걸 확인하고 **업데이트 추적이 되는 소비 방식**으로 선회했다.

### 내용

외부 스킬 도입 결정 트리:

```
외부 스킬을 쓰고 싶다
├─ 원본 그대로 + 업스트림 업데이트 받고 싶다
│   └─ 원본 repo에 .claude-plugin/marketplace.json 있나?
│       ├─ 있음 → /plugin marketplace add <owner/repo> + /plugin install <name>@<mkt>
│       │         (서드파티는 auto-update 기본 OFF → /plugin marketplace update 수동, 또는 "autoUpdate": true)
│       └─ 없음 (zip/디렉토리 배포 skill) → configs/external-skills.tsv에 선언 → install.sh가 재현
│                 (clone→npm→심링크, repo 밖 clone, git pull로 갱신. 아래 "외부 skill 방식" 참조)
├─ 내 repo 안에서 버전 추적하며 관리하고 싶다
│   └─ git submodule (skills/ 또는 vendor/) — 단 커스터마이징 시 충돌, 커맨드 네임스페이스 정리 필요
└─ 경량화/내 식 커스터마이징이 우선, 업데이트는 포기 가능
    └─ 직접 작성 (write-a-skill). "영감만" 차용 시 출처 귀속, MIT면 LICENSE 보존
```

**외부 skill 방식 (marketplace.json 없는 경우, 2026-07 확립):**
- plugin `/plugin`은 marketplace.json이 있어야 동작. 없으면 이 repo는 `configs/external-skills.tsv` + `install.sh install_external_skills()`로 대신 재현한다.
- 자체 skill 심링크(`skills/*` → `~/.claude/skills/*`)와 **동일한 모델, source만 외부 repo**. `k8s-study-lab`이 다른 로컬 repo를 가리키는 것과 같은 패턴 (repo에 vendoring 안 함).
- clone 위치 기본값은 **개인 경로 금지** → `~/.claude/external-skills` (다른 사람도 쓰는 repo이므로 `~/dev/<user>/` 같은 개인 경로를 박으면 pre-commit hook의 로컬경로 검사에 걸리고 남의 홈에 이상한 경로가 생김). `EXTERNAL_SKILLS_DIR`로 조정 가능.
- npm 의존성은 `package.json` 있을 때만 조건부 설치. idempotent (clone/npm/심링크 모두 "이미 있으면 스킵").
- 문서: [external-plugins.md](../external-plugins.md) "외부 Skills (plugin 아님)" 섹션.
- 사례: archify (다이어그램 생성 skill, MIT). plugin이 아니라 skill zip 배포라 이 경로로 등록. → **2026-07-09 비활성화** (그리기 품질 미흡). 메커니즘 검증용 첫 사례로서의 가치는 남으므로 tsv에서 주석 처리만, 로직·문서는 유지.

핵심 사실 (공식 문서, 2026-06 기준):
- plugin은 **install.sh 심링크 모델과 별개 시스템** (`~/.claude/plugins/`에서 독립 관리). "내 repo로 가져와 관리"가 아니라 "repo 밖에서 소비"다.
- plugin 스킬은 `/plugin-name:skill-name`으로 **네임스페이스** → 내 `~/.claude/skills/`의 `/skill-name`과 충돌 안 함. 단 **기능 중복**은 사용자 혼란이라 한쪽 제거 권장.
- 서드파티 마켓플레이스는 auto-update 기본 OFF (공식 Anthropic 마켓플레이스만 ON).
- `/plugin ...`은 **CLI 내장 인터랙티브 커맨드** — Claude(도구)가 대신 실행 못 함. 사용자가 직접 입력해야 함.

### 왜 중요한가

- 다음에 외부 스킬을 만나면 *"베낄까 말까"* 이분법이 아니라 위 3갈래로 바로 판단
- **업데이트 추적 비용을 의사결정에 넣는다**: 직접 베끼기는 "지금 편하지만 영원히 stale". 자주 갱신되는 외부 스킬일수록 plugin/submodule이 유리
- 기능 중복 시 한쪽을 `_disabled/`로 빼 충돌·혼란 제거 (mmdraw·humanize-ko 동일 패턴)

