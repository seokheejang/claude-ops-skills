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
