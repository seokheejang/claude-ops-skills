# Skill Split + Best-Practice Enhancements + Code-Reviewer Backlog

**날짜**: 2026-05-08
**상태**: 완료 (code-reviewer agent 도입은 별도 backlog로 이월)

## 배경

- write-a-skill 스킬을 도입하면서 100줄 SKILL.md 룰을 정립했고, 그 룰을 기존 스킬에 적용해야 했음.
- 100줄 초과 스킬: mmdraw(267), compound(247), best-practice(167), ralph(121).
- 동시에 외부 자료(Jeffallan/claude-skills, mattpocock/skills) 흡수와 K8s 작성/조회 스킬 분리가 필요했음.
- best-practice는 `grill-me`로 검토하면서 6개 정책 보완이 도출되었고 ralph도 같은 방식으로 검토됨.
- ralph 검토 결과 L1+L2(라인/함수 동작)에 한정되며, L3(버그/품질) 영역을 다룰 code-reviewer agent가 별도 필요하다는 결론.

## 변경 내용

### 신규 스킬

| 파일/디렉토리 | 변경 | 설명 |
|---------------|------|------|
| `skills/grill-me/` | 신규 | mattpocock/skills 원본 (MIT). 계획/설계 스트레스 테스트용 인터뷰 스킬 |
| `skills/write-a-skill/` | 신규 | mattpocock/skills 베이스 + 우리 컨벤션. 메타 스킬 — 100줄 룰, 보안, kebab-case 강제 |
| `skills/k8s-craft/` | 신규 | Jeffallan/claude-skills 베이스 (MIT). manifest 작성/설계 전용. k8s-ops와 페어링 (조회/작성 분리) |

### 분할 작업 (4개 스킬 모두 SKILL.md ≤ 100줄)

| 스킬 | 변경 전 | 변경 후 | 분리 단위 |
|------|---------|---------|----------|
| mmdraw | 267줄 단일 | 97줄 + REFERENCE.md + scripts/render.sh | 문법 규칙 → REFERENCE, 렌더링 → 결정론적 스크립트 |
| compound | 247줄 단일 | 97줄 + references/ 3개 | work-doc, learnings, changelog 토픽별 분리 |
| best-practice | 167줄 단일 | 86줄 + references/ 3개 | sources, verification, output |
| ralph | 121줄 단일 | 96줄 + references/ 2개 | checklists, policy |

### 외부 자료 흡수

| 흡수 위치 | 출처 (모두 MIT, attribution 헤더 포함) |
|----------|---------------------------------------|
| `skills/k8s-craft/references/` (8개) | Jeffallan/claude-skills — workloads, networking, configuration, storage, cost-optimization, custom-operators, service-mesh, multi-cluster |
| `skills/k8s-ops/references/troubleshooting.md` | Jeffallan/claude-skills |
| `skills/argocd-ops/references/gitops.md` | Jeffallan/claude-skills |
| `skills/helm-ops/references/helm-charts.md` | Jeffallan/claude-skills (chart authoring deep-dive, 912줄) |

### best-practice 6개 보완 (grill-me 면접 결과)

1. AI 콘텐츠 식별 휴리스틱 (의심 신호 5개 + 처리 절차)
2. Citation 검증 절차 (URL fetch + 인용 내용 확인 — 환각 방지)
3. 출처 독립성 (1차 출처 추적, 에코 챔버 방지)
4. 도메인별 시의성 표 (K8s 1년, Helm 2년, SRE 5년+ 등 9개 도메인)
5. 학습 기록 우선 검색 (외부 검색 전, working dir 명시 — claude-ops-skills가 아닌 사용자 프로젝트)
6. 결과 끝 학습 저장 권유 (의미 있는 결과 시 `/compound` 호출 트리거)

### ralph 페어링 정의 (grill-me 면접 결과)

ralph 범위를 L1+L2로 명시. 다음 영역은 별도 도구로 위임:
- L3 단순화/중복 → code-simplifier agent (Anthropic plugin)
- L3 버그/로직/보안/품질 → **code-reviewer agent (도입 예정 — 다음 세션 backlog)**
- L4 설계/트레이드오프 → /grill-me
- L4 아키텍처 → 사람 리뷰, ADR

### pre-commit 훅 강화

- SKILL.md frontmatter 필수 필드 검증 (name, description)
- credential 정규식: `<PLACEHOLDER>`, `${VAR}`, `${{ ... }}` (GitHub Actions), 작은따옴표 placeholder, manifest 키워드(`secretRef`, `valueFrom`) 예외 추가
- IP 정규식: 공개 DNS (8.8.8.8/4.4, 1.1.1.1/0.0.0.1) + RFC 5737 문서용 대역 (192.0.2/24, 198.51.100/24, 203.0.113/24) 예외 추가

## 결과

- 모든 SKILL.md 100줄 룰 준수 (가장 긴 SKILL.md = mmdraw 97줄)
- 5개 커밋 분할: mmdraw 분할 (49ccb19), grill-me/write-a-skill 도입 (17d3e41), k8s 분리 + 흡수 (ccd05ac), compound/ralph 분할 (852586a), best-practice 분할 + 6개 보완 (942bcfe)
- pre-commit 훅: 모든 단계에서 통과
- 외부 자료의 fake credential 자동 치환: `MyPassword123` → `<PASSWORD>`, `sk-1234567890abcdef` → `<API_KEY>`, `YOUR_TOKEN` → `<KUBECOST_TOKEN>` 등

## 핸드오프 — 다음 세션에서 이어갈 작업

### code-reviewer agent 도입 (옵션 C: plugin 베이스로 customize)

**목표**: ralph가 다루지 못하는 L3 영역(bugs, logic errors, security, code quality, project conventions)을 별도 agent로 다룸.

**진행 절차**:

1. **베이스 복사**:
   - 출처: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev/agents/code-reviewer.md`
   - 또는: `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/pr-review-toolkit/agents/code-reviewer.md`
   - → `agents/code-reviewer.md`로 복사

2. **우리 컨벤션 통합**:
   - 한국어 응답 명시
   - CLAUDE.md 보안 체크리스트 7항목 통합 (로컬 경로/인프라명/kubeconfig/IP/credentials/예시 일반화/.gitignore)
   - K8s READ-ONLY 룰 통합
   - 우리 도메인 반영 (DevOps, blockchain RPC, Helm, ArgoCD)
   - 출처 attribution 헤더

3. **검증 호출**:
   - 최근 작업한 코드(예: best-practice 분할, k8s-craft references)에 호출
   - 결과 품질 평가 → 만족/추가 customize/폐기 결정

4. **ralph 페어링 표 갱신**:
   - 현재 ralph SKILL.md에 *"code-reviewer agent (도입 예정)"* placeholder가 있음
   - 도입 후 *"도입 예정"* 표기 제거, agent 경로 정확히 표기

5. **README 등록**:
   - Agents 표에 code-reviewer 한 줄 추가

**참고할 만한 결정 사항** (이번 세션 grill-me 결과):
- **이름은 `code-reviewer` 그대로** — 업계 표준 명명
- **PR 자동 코멘트 기능은 제외** — `/review`, `/code-review` 슬래시 커맨드가 이미 그 영역. 우리는 로컬 git diff 기반 즉시 검토용
- **simplify와 영역 분리**: code-reviewer는 *"버그/품질/보안"*, simplify는 *"단순화/명확성"*. 두 도구는 다른 시점에 호출됨

### 추가 backlog (낮은 우선순위)

- code-reviewer 도입 후 ralph SKILL.md의 페어링 표에서 *"도입 예정"* 표기 제거
- best-practice의 6개 보완을 실제 호출로 검증 (Citation 검증이 실전에서 잘 작동하는지)
- k8s-craft를 실제 manifest 작성 작업에 호출해서 Safety Rules가 잘 강제되는지 확인 (kubectl apply 직접 실행 차단)
