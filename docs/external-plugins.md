# External Plugins

이 repo의 자체 스킬(`skills/`, install.sh가 심링크) **외에** 수동으로 설치하는 외부 Claude Code 플러그인 목록.

> 왜 별도 관리: 플러그인은 install.sh 심링크 모델과 **별개 시스템**(`~/.claude/plugins/`)이라
> install.sh가 건드리지 않는다. 새 머신에서 재현하려면 아래 명령을 직접 실행해야 한다.
> 도입 기준(베끼기 vs plugin vs submodule)은 [learnings/claude-code.md](learnings/claude-code.md) 참조.

## 설치된 플러그인

| 플러그인 | 마켓플레이스 | 용도 | 비고 |
|----------|------------|------|------|
| `humanize-korean` | `epoko77-ai/im-not-ai` (MIT) | AI가 쓴 한국어 글 윤문 (내용 보존, 문체만) | 커맨드: `/humanize-korean:humanize` |

## 설치 방법

```
/plugin marketplace add epoko77-ai/im-not-ai
/plugin install humanize-korean@im-not-ai
```

- `/plugin ...`은 Claude Code CLI 내장 인터랙티브 커맨드 — 세션에서 직접 입력 (스크립트 자동화 불가).
- 설치 스코프는 설치 시 선택 (user = 전체 프로젝트 / project / local). 개인용 도구는 user 스코프 권장.
- 플러그인 스킬은 `/<plugin-name>:<skill-name>`으로 네임스페이스 → 이 repo의 `/skill-name`과 충돌 없음.

## 업데이트

서드파티 마켓플레이스는 **자동 업데이트가 기본 OFF** (공식 Anthropic 마켓플레이스만 ON).
업스트림 갱신을 받으려면 둘 중 하나:

- 수동: `/plugin marketplace update epoko77-ai/im-not-ai`
- 자동: `/plugin` → Marketplaces 탭에서 해당 마켓플레이스의 autoUpdate 토글 ON

## 새 플러그인 추가 시

1. [learnings/claude-code.md](learnings/claude-code.md)의 "외부 스킬 3갈래 결정 트리"로 plugin이 맞는 방식인지 확인
2. 위 표에 한 줄 추가 (플러그인명 / 마켓플레이스 / 용도 / 커맨드)
3. 기능이 이 repo 자체 스킬과 중복되면 한쪽을 `_disabled/`로 빼 혼란 제거
