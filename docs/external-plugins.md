# External Plugins

이 repo의 자체 스킬(`skills/`, install.sh가 심링크) **외에** 수동으로 설치하는 외부 Claude Code 플러그인 목록.

> 왜 별도 관리: 플러그인은 install.sh 심링크 모델과 **별개 시스템**(`~/.claude/plugins/`)이라
> install.sh가 건드리지 않는다. 새 머신에서 재현하려면 아래 명령을 직접 실행해야 한다.
> 도입 기준(베끼기 vs plugin vs submodule)은 [learnings/claude-code.md](learnings/claude-code.md) 참조.

## 설치된 플러그인

| 플러그인 | 마켓플레이스 | 용도 | 비고 |
|----------|------------|------|------|
| `humanize-korean` | `epoko77-ai/im-not-ai` (MIT) | AI가 쓴 한국어 글 윤문 (내용 보존, 문체만) | 커맨드: `/humanize-korean:humanize` |
| `ponytail` | `DietrichGebert/ponytail` (MIT) | 코드 생성 *전* 과잉설계 차단 가드레일 (YAGNI·stdlib 우선·결정 사다리) | 커맨드: `/ponytail [lite\|full\|ultra\|off]`, `/ponytail-review`, `-audit`, `-debt`, `-gain` |

## 설치 방법

```
# humanize-korean
/plugin marketplace add epoko77-ai/im-not-ai
/plugin install humanize-korean@im-not-ai

# ponytail
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

- `/plugin ...`은 Claude Code CLI 내장 인터랙티브 커맨드 — 세션에서 직접 입력 (스크립트 자동화 불가).
- 설치 스코프는 설치 시 선택 (user = 전체 프로젝트 / project / local). 개인용 도구는 user 스코프 권장.
- 플러그인 스킬은 `/<plugin-name>:<skill-name>`으로 네임스페이스 → 이 repo의 `/skill-name`과 충돌 없음.

## 역할 구분 (겹치는 도구)

ponytail은 코드 단순화 영역에서 Claude Code **내장** 스킬과 인접하다. 언제 뭘 쓰는지:

| 시점 | 도구 | 동작 |
|------|------|------|
| 코드 생성 **전** | `/ponytail` (full 기본) | 결정 사다리로 과잉설계를 애초에 막음 (가드레일) |
| 변경 후, 단순화 | 내장 `/simplify` | 변경분을 재사용·간결화로 고쳐 적용 (write) |
| 변경 후, 적발만 | `/ponytail-review` | diff의 과잉설계만 읽기 전용 리포트 (no write) |
| 변경 후, 버그+품질 | 내장 `/code-review` | 정확성 버그까지 포함 (ponytail-review는 버그 제외) |

요약: **ponytail 본체 = 생성 시점 예방, simplify/code-review = 사후 교정.** `/ponytail-review`와 `/code-review`는
초점이 다르다 — 전자는 "뭘 지울 수 있나"만, 후자는 정확성·보안까지.

> ponytail의 벤치마크(54% less code 등)는 5개 소규모 태스크 기준 — 대규모/도메인 복잡 코드로 일반화되는 수치는 아니다.

## 업데이트

서드파티 마켓플레이스는 **자동 업데이트가 기본 OFF** (공식 Anthropic 마켓플레이스만 ON).
업스트림 갱신을 받으려면 둘 중 하나:

- 수동: `/plugin marketplace update epoko77-ai/im-not-ai`
- 자동: `/plugin` → Marketplaces 탭에서 해당 마켓플레이스의 autoUpdate 토글 ON

## 새 플러그인 추가 시

1. [learnings/claude-code.md](learnings/claude-code.md)의 "외부 스킬 3갈래 결정 트리"로 plugin이 맞는 방식인지 확인
2. 위 표에 한 줄 추가 (플러그인명 / 마켓플레이스 / 용도 / 커맨드)
3. 기능이 이 repo 자체 스킬과 중복되면 한쪽을 `_disabled/`로 빼 혼란 제거
