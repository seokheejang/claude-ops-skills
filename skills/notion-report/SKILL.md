---
name: notion-report
description: 작업 결과물을 사람이 읽기 편한 한국어 Notion 문서로 옮긴다. 대화/작업 내용 정리, 장애 분석 리포트, 리서치 문서, 회의 자료, 스펙→작업 분해 — 4개 템플릿 중 목적에 맞는 것을 골라 Notion에 페이지를 만든다. Use when 사용자가 "노션에 정리해줘", "노션에 옮겨줘", "노션 문서 만들어줘", "/notion-report", "Notion에 저장", "리포트 남겨줘" 라고 할 때.
effort: high
---

# Notion Report

작업물 → 한국어 Notion 페이지. 템플릿 4종은 Notion 공식 플러그인(Notion Cookbook)에서 가져와 이 환경에 맞게 고친 것.

## 공통 규칙 (모든 템플릿에 적용)

- **문서는 한국어로 쓴다.** 제목·헤딩·본문 전부. 각 `GUIDE.md` / `reference/` 는 영어로 되어 있지만 그건 **구조의 예시일 뿐 언어의 예시가 아니다.**
- **문체는 하십시오체(존댓말)로 쓴다.** 종결어미는 `~입니다` / `~합니다` / `~했습니다`. 해라체(`~한다`, `~이다`, `~아니다`)와 해요체(`~해요`, `~예요`)는 쓰지 않는다. 이 `SKILL.md` 와 각 `GUIDE.md` 는 해라체로 쓰여 있지만 그건 **지시문의 문체일 뿐 산출물의 문체가 아니다.**
  - 표의 셀, 불릿 항목, 헤딩처럼 명사구로 끝나는 자리는 종결어미를 붙이지 않고 명사구로 둔다
  - 코드블록·로그·에러 메시지 원문에는 적용하지 않는다
- **기술 용어와 출력은 번역하지 않는다.** 리소스명, 명령어, 로그 라인, 에러 메시지, URL은 원문 그대로.
- **명령 출력·YAML·로그는 코드블록에 원문 그대로 넣는다.** 다시 타이핑하거나 "정리"하지 않는다. 길면 앞뒤를 자르고 `(중략)` 을 남긴다 — 값을 바꾸지 않는다.
- **인라인 코드(백틱)는 "그대로 복사해 써야 정확한 것"에만 쓴다.** 백틱이 많으면 문장이 읽히지 않는다.
  - 쓴다: 리소스·호스트명, 파일 경로, 명령어·플래그, 필드/키 이름, 값(IP·포트·버전·해시), 에러 문자열 원문
  - 안 쓴다: 일반 명사(파드, 노드, 클러스터, 네임스페이스), 제품명(Kubernetes, ArgoCD, Grafana, Terraform), 사람 말로 푼 설명, 단순 강조 — 강조는 **볼드**로 한다
  - 같은 값이 한 섹션에서 반복되면 **처음 한 번만** 백틱을 씌우고 이후에는 평문으로 쓴다
  - 한 문장에 백틱이 3개를 넘으면 그 문장은 표나 코드블록으로 뺀다
- **저장 위치는 만들기 전에 물어본다.** 부모 페이지를 추측하지 않고, 새 데이터베이스를 임의로 만들지 않는다.
- **확인 못 한 것은 `(미확인)` 으로 남긴다.** 추론으로 채우지 않는다.
- 툴은 claude.ai 커넥터 네임스페이스: `mcp__claude_ai_Notion__notion-*`. `Notion:` 접두사 툴은 이 환경에 없다.

## GUIDE.md 의 절차를 그대로 따르지 않는다

각 `GUIDE.md` 는 업스트림 원본이라 **확인 절차가 아예 없다.** 4개 템플릿 전부 Quick Start 가 "검색 → 즉시 생성" 으로 이어진다. 구조만 참고하고, 아래 지점은 이 문서의 「절차」로 대체한다. **구체적인 단계가 적혀 있어도 이 `SKILL.md` 가 우선한다.**

| GUIDE.md 의 지시 | 이 환경에서 |
|---|---|
| Quick Start·워크플로의 페이지 생성 단계 (4개 템플릿 전부) | 저장 위치와 본문 구조를 **먼저 사용자에게 확인받는다.** 승인 없이 `notion-create-pages` 를 호출하지 않는다 |
| knowledge-capture Step 6 "Make content discoverable" — 허브·팀 위키 홈페이지·부모 페이지를 `notion-update-page` 로 수정 | **기본적으로 하지 않는다.** 새로 만든 페이지 외의 문서는 사용자가 링크를 걸어달라고 요청했을 때만 수정한다 |
| knowledge-capture Common Issues 의 "Not sure where to save → Default to general wiki" | **추측하지 않고 물어본다.** 위 공통 규칙이 우선한다 |
| spec-to-implementation Step 6~7 — 태스크 다건 생성 + 기존 페이지 status 변경 | 만들 태스크 목록을 **먼저 보여주고 동의를 받는다.** 기존 페이지의 속성 변경은 대상 페이지를 명시해서 따로 확인받는다 |
| meeting-intelligence Step 5 — 참석자 전원에게 공유되는 external agenda 생성 | 외부에 공유되는 문서이므로 **본문 전체를 사용자에게 보여주고 승인받은 뒤에 만든다** |
| `reference/*-database.md` 의 `notion-create-database` 사용법 | 사용자가 **데이터베이스 생성을 명시적으로 요청했을 때만** 참고한다 |

## 템플릿 선택

| 무엇을 옮기나 | 템플릿 | 상세 |
|---|---|---|
| 이 세션의 작업 내용·결정·트러블슈팅 결과·How-to | **knowledge-capture** | [knowledge-capture/GUIDE.md](knowledge-capture/GUIDE.md) |
| 조사 결과 (도구 비교, 도입 검토, 워크스페이스 검색 종합) | **research-documentation** | [research-documentation/GUIDE.md](research-documentation/GUIDE.md) |
| 회의 준비 자료 (사전 리드 + 아젠다) | **meeting-intelligence** | [meeting-intelligence/GUIDE.md](meeting-intelligence/GUIDE.md) |
| 스펙 → 구현 작업 분해·진행 추적 | **spec-to-implementation** | [spec-to-implementation/GUIDE.md](spec-to-implementation/GUIDE.md) |

애매하면 **knowledge-capture** 가 기본값이다. 두 개에 걸치면 하나를 고르고 왜 골랐는지 한 줄로 말한다.

## 절차

1. **옮길 내용 확정** — 세션에서 무엇을 문서화할지 사용자에게 한 줄로 확인받는다. 대화 전체가 아니라 결론과 근거가 대상이다.
2. **템플릿 선택** — 위 표에서 고르고 해당 `GUIDE.md` 를 읽는다. 그 안의 `reference/` 는 필요할 때만 읽는다.
3. **저장 위치 확인** — `mcp__claude_ai_Notion__notion-search` 로 후보를 찾아 **사용자에게 제시하고 고르게 한다.** 기존 문서가 있으면 새로 만들지 말고 업데이트를 제안한다.
4. **본문 작성 → 사용자에게 보여준다** — Notion에 쓰기 전에 구조(제목/섹션 목록)를 먼저 보여주고 동의를 받는다.
5. **생성** — `mcp__claude_ai_Notion__notion-create-pages` (수정은 `notion-update-page`). 끝나고 페이지 URL을 출력한다.

## 운영 작업물을 옮길 때 (이 환경 특화)

DevOps 작업 결과를 옮기는 경우 문서 최상단에 이 메타데이터를 먼저 박는다:

```
- 대상: <cluster context / namespace / host / chain>
- 시각: <사용자가 명령을 실행한 시각, 모르면 (미확인)>
- 실행자: 사용자가 붙여넣은 실측 / Claude 추론 — 둘을 섞지 않고 구분해서 표기
```

- 붙여넣은 출력이 **어느 컨텍스트에서 나왔는지 불분명하면 그것부터 되묻는다.** 추측한 컨텍스트를 문서에 적으면 나중에 그게 근거로 쓰인다.
- 조치 사항은 **증상 차단 / 완화 / 근본 수정** 중 무엇인지 분류해서 적는다.
- 아직 실행하지 않은 명령은 "제안" 섹션에 두고, 실행한 것과 섞지 않는다.

## 금지

- Notion에 쓰기 전에 사용자 확인 없이 페이지를 만드는 것
- 붙여넣은 출력을 요약·재작성해서 원문 대신 넣는 것
- 데이터베이스를 새로 만드는 것 (사용자가 명시적으로 요청할 때만)
- 새로 만든 페이지 외의 문서를 수정하는 것 (허브 페이지·팀 위키 홈페이지에 링크 추가 포함) — 사용자가 대상 페이지를 지정해서 요청했을 때만 한다
- 페이지 삭제·아카이브 (이 스킬은 페이지 생성과, 사용자가 지정한 페이지의 업데이트만 한다)

## 출처

`knowledge-capture/`, `meeting-intelligence/`, `research-documentation/`, `spec-to-implementation/` 는
[makenotion/claude-code-notion-plugin](https://github.com/makenotion/claude-code-notion-plugin) (`9847f2a`, 2026-01-22)
의 `skills/notion/` 에서 가져왔다. 원본 repo에 LICENSE 파일은 없다.

이 repo에서 변경한 것:
- 툴 이름 `Notion:notion-*` → `mcp__claude_ai_Notion__notion-*` (claude.ai 커넥터 네임스페이스)
- 각 `SKILL.md` → `GUIDE.md` 개명 (중첩 스킬로 오인 등록되는 것 방지)
- `evaluations/` 삭제 (업스트림 테스트 픽스처)
- `examples/` 14개 삭제 (2026-09) — 전부 영어 산출물 샘플이라 위 「문서는 한국어로 쓴다」 규칙과 충돌했고, `trip-planning`·`market-research`·`competitor-analysis` 는 이 환경의 용도와 무관했다
- `reference/` 중 Notion 사용법 설명 5개 삭제 (2026-09) — `advanced-search`, `citations`, `spec-parsing`, `task-creation`, `progress-tracking`. MCP 툴 스키마를 직접 읽으므로 중간 설명서가 필요 없다. **문서 구조를 정의하는 `*-format` / `*-template` / `*-database` 는 남겼다**
- 이 `SKILL.md` (라우터 + 공통 규칙)는 새로 작성
