# Changelog

claude-ops-skills 다음 작업(Backlog) + 작업 이력 관리.
세부 내용은 각 문서 링크 참조. 스킬 신규 아이디어 상세는 [TODO.md](TODO.md).

## 다음 작업 후보 (Backlog)

### 우선순위 높음
- [x] **code-reviewer agent 도입**: 하네스 기본 `/code-review`(effort low~max) + `/simplify`로 충족 → 자체 구현 불필요. ralph 페어링 표를 실물 명령으로 교체 (v1.0)
- [ ] **skill 실전 테스트**: 각 skill을 실제 운영 환경에서 호출하여 워크플로우 검증 (특히 best-practice 6개 보완 실전 검증, k8s-craft Safety Rules 강제 확인)
- [ ] **agent 실전 테스트**: k8s-debugger, rpc-monitor를 실제 이슈 상황에서 사용해보기

### 중간 우선순위
- [x] **K8s 보안 skill + agent**: 클러스터 보안 점검 자동화 (RBAC, NetworkPolicy, PodSecurity 등 감사) → v0.4
- [ ] **Helm Generator/Validator**: Helm chart 생성 + 검증 skill 쌍
- [ ] **Terraform Generator/Validator**: Terraform 코드 생성 + plan 검증 skill 쌍
- [ ] **Generator/Validator 패턴 도입**: 필요시 k8s-yaml-validator 등 추가
- [ ] **프로젝트별 skill 적용**: 다른 프로젝트 repo에 `.claude/skills/` 추가 테스트
- [ ] **새 skill 후보**: promql-generator, log-search, infra-report 등
- [ ] **hook 테스트 강화**: BATS 기반 테스트 suite 추가 (oryband 참고)

### 낮은 우선순위
- [ ] **settings.local.json 정리 스크립트**: 중복 규칙 자동 제거
- [ ] **zshrc alias**: 자주 쓰는 조합 단축키 추가

## 작업 이력

### v1.0 — Opus 5 대응 정리 (2026-08-10)

모델이 이미 아는 지식을 덜어내고, 스킬을 **가드레일 + 판정 기준 + 명령 생성기**로 재정의.

**제거**
- `compound`, `rpc-health` 스킬 삭제 (사용자 요청) — 참조하던 7곳(troubleshoot, best-practice, rpc-agent, agents/rpc-analytics, agents/rpc-monitor, README, CLAUDE.md) 복구
- `references/` 5,773줄 삭제: k8s-craft 8개(3,899) · helm-ops(918) · argocd-ops(536) · k8s-ops(420). 표준 YAML/설치 명령/문법 레퍼런스는 모델이 알고, 적어두면 버전이 낡아 **틀린 답의 근거**가 된다
- `clusters.yaml` 자동 생성 비활성화 — install.sh 호출부 주석 처리(함수는 보존), 로컬 파일·example 삭제

**실행 모델 전환** — k8s-ops, k8s-security, helm-ops(릴리스 모드), argocd-ops, db-ops, ssh-ops
- "Claude가 직접 실행" → **"복붙 가능한 READ-ONLY 명령 묶음 출력 + 붙여넣은 출력 해석"**
- 6개 스킬 모두 `실행 모델` + `Arguments` 섹션을 **인라인으로** 보유 (초안은 k8s-ops에 위임했으나, 스킬 단독 호출 시 그 규칙을 못 읽어서 전부 펼침)
- 왕복을 줄이기 위해 1차 진단 묶음을 한 덩어리로, 스크린샷에 담기게 `--no-headers`/`jsonpath`/`head` 적용
- `--context` 명시 강제, 미확인 항목은 `(미확인)` — 특히 k8s-security는 "안 돌린 도메인을 통과로 처리 금지"를 명시
- helm-ops 차트 모드와 terraform-ops는 로컬 파일 대상이라 **직접 실행 유지**

**/ralph 검증에서 잡은 결함 (3라운드)**
- **k8s-security RBAC 감사가 동작하지 않았다** — jsonpath 필터 안 `[*]` 와일드카드는 kubectl이 지원하지 않고(`string is not array or slice`), 통과했더라도 `@.rules[*].verbs[0]`은 각 rule의 **첫 verb만** 검사해 `verbs: [get, "*"]`를 놓친다. 보안 감사가 조용히 "No issues found"를 내는 실패 모드 → jq로 교체 후 합성 JSON으로 검증
- **"복붙 가능한 블록"이 복붙되지 않았다** — `CTX=<context>`의 `<`를 셸이 리다이렉션으로 파싱해 블록 전체가 syntax error. 5개 스킬 placeholder 인용 처리 + `REL`/`NS`/`APP` 변수화. `bash -n` 회귀 검사 추가
- **ssh-ops 1차 묶음에 ssh 래퍼가 없었다** — 복붙하면 원격이 아니라 로컬 머신을 조회한다 → 자립형 `ssh ... "$HOST" '...'` 단일 호출로 교체

**보안**
- deny 규칙 31 → 61개. SKILL.md 산문에만 있던 금지 명령을 실제 게이트로 승격: `terraform state rm/mv/push/pull`·`import`·`taint`·`force-unlock`·`workspace new/delete/select`·`init -upgrade`·`console`, `argocd app rollback/terminate-op/set/patch`·`repo/cluster/proj` 변경·`login`, `helm repo add/remove/update`·`plugin install`·`dependency update`

**기타**
- ralph 유지, `code-reviewer agent (도입 예정)` placeholder → `/code-review`·`/simplify` 실물 교체
- write-a-skill에 "모델이 이미 아는 건 쓰지 않는다" 방침 추가 — `references/`는 방법론 전용
- **SKILL.md 길이 룰 100줄 → 150줄** (write-a-skill SKILL.md/REFERENCE.md, templates/). 여유분은 분량 채우기가 아니라 **위임 대신 인라인**에 쓴다는 단서 포함
- troubleshoot description 628자 → 296자

### v0.9 — Skill 분할 + 신규 스킬 + best-practice 보완 (2026-05-08)

- [06-skill-split-and-best-practice-enhancements.md](archive/06-skill-split-and-best-practice-enhancements.md) 작업 문서
- 신규 스킬 3개: `grill-me` (mattpocock/skills, MIT), `write-a-skill` (메타 스킬, 100줄 룰 + 보안 강제), `k8s-craft` (K8s manifest 작성/설계, k8s-ops와 페어링)
- 4개 SKILL.md 100줄 룰 적용: mmdraw 267→97, compound 247→97, best-practice 167→86, ralph 121→96. 분할 단위 = REFERENCE.md (1~2 토픽) / references/ (3+ 토픽) / scripts/ (결정론적 작업)
- 외부 자료 흡수 (Jeffallan/claude-skills, MIT): k8s-craft references/ 8개, k8s-ops/argocd-ops/helm-ops에 troubleshooting/gitops/helm-charts 깊이 보강. fake credential 자동 placeholder 치환
- best-practice 6개 보완: AI 콘텐츠 식별, Citation 검증, 출처 독립성, 도메인별 시의성, learnings 우선 검색, 결과 저장 권유
- ralph 페어링 정의: L1+L2 한정 명시. L3는 code-simplifier/code-reviewer, L4는 grill-me/사람으로 위임
- pre-commit 훅 강화: SKILL.md frontmatter 검증, credential 정규식에 `${{ ... }}`/placeholder/manifest 키워드 예외, IP 정규식에 공개 DNS + RFC 5737 문서용 대역 예외
- [claude-code.md](learnings/claude-code.md) 학습 2건 추가: 분할 단위 결정 트리, 자기 검증 도구 다층 매핑

### v0.8 — ssh-ops / db-ops / rpc-agent 강화 (2026-04-17)

- [05-skill-hardening.md](archive/05-skill-hardening.md) 작업 문서
- `ssh-ops`: SSH 연결 정책 명시 (BatchMode, ConnectTimeout=10, StrictHostKeyChecking=accept-new, ServerAliveInterval=30) — 자동화 흐름에서 prompt/hang/MITM 방지
- `db-ops`: `db-targets.yaml` 도입 (clusters.yaml 패턴 차용), `password_env`로 비밀번호 간접 참조, Target Resolution + MySQL/PG 연결 패턴 명시, `.gitignore` + CI forbidden list 3중 방어
- `rpc-agent`: `gas-analysis`(EVM 전용) / `block-time-analysis`(EVM+Cosmos) 구현 스펙 완성. `address-activity`는 RPC 단독 비효율로 "인덱서 권장" scope-out
- pre-commit / CI credential 검사: bash 변수 참조(`${!VAR}` 등) false positive 제외
- [claude-code.md](learnings/claude-code.md) 학습 기록: SKILL.md는 세션 시작 시 캐시됨 → 같은 세션에서 수정 후 테스트 불가

### v0.7 — best-practice Skill + README 개선 (2026-04-08)

- [04-best-practice-readme.md](archive/04-best-practice-readme.md) 작업 문서
- `best-practice` 스킬 추가: 업계 사례/커뮤니티/공식 문서 기반 체계적 리서치 (5단계 워크플로우, 구조화된 출력)
- README.md 개선: Description 확장, Table of Contents, Prerequisites, Quick Start 확장, 세부 섹션 접이식 처리

### v0.6 — mmdraw + compound 스킬 추가 (2026-04-08)

- [03-mmdraw-compound-skills.md](archive/03-mmdraw-compound-skills.md) 작업 문서
- `mmdraw` 스킬 추가: 소스/문서 분석 → Mermaid 다이어그램 생성 (문법 검증 포함)
- `compound` 스킬 추가: Compound Engineering 기반 작업 종합 (학습 축적, 문서 정리, CHANGELOG 연동)
- `docs/learnings/`, `docs/archive/`, `docs/diagrams/` 디렉토리 구조 도입
- Excalidraw JSON 직접 생성 방식 시도 후 폐기 → Mermaid 기반으로 전환 (학습 기록 참조)

### v0.5 — GitHub Actions Security Check (2026-03-09)
- `.github/workflows/security-check.yml` 추가: PR/push 시 자동 보안 검사
- 6개 체크 항목: 금지 파일, 개인 경로, credential, skill 구조, mutating kubectl, 하드코딩 IP
- CLAUDE.md 보안 체크리스트를 CI로 자동화

### v0.4 — K8s Security Audit + Cluster Aliases (2026-03-09)
- [02-skill-quality-improvement.md](archive/02-skill-quality-improvement.md) (K8s Security Audit / Cluster Aliases 섹션)
- `k8s-security` skill 추가: 7개 보안 도메인 점검 (RBAC, NetworkPolicy, Pod Security, Container Config, Secrets/SA, Services, Image Security)
- `k8s-security-auditor` agent 추가: 종합 보안 감사 워크플로우 (위험도 분석, 상관관계 분석, 개선 가이드)
- Cluster aliases 기능: `clusters.yaml`에 `aliases` 필드 추가, 짧은 이름으로 클러스터 지정 가능
- `README.md` 업데이트: Skills/Agents 테이블, Cluster Aliases 섹션 추가

### v0.3 — PreToolUse Hook 도입 (2026-03-09)
- 복합 Bash 명령(파이프, 체이닝, 리다이렉트) 자동 승인 hook 추가
- `shfmt` AST 파싱으로 모든 서브 명령을 검증 (settings.json allow/deny 재사용)
- `install.sh` hooks 머지 로직 추가 + `shfmt` 필수 의존성 추가
- `settings.json.template` allow 패턴 개선 + hooks.PreToolUse 섹션 추가
- Makefile 추가 (`make install`, `make test`)
- 참고: oryband/claude-code-auto-approve

### v0.2 — Skills & Agents 품질 개선 (2026-03-08)
- [02-skill-quality-improvement.md](archive/02-skill-quality-improvement.md)
- 4개 skill SKILL.md 체계적 워크플로우로 개선 (When to Use, Step-by-Step, Troubleshooting, 판정 기준)
- 2개 agent 정의 강화 (Investigation Protocol, Severity Levels, Report Format)
- 참고: wshobson/agents, akin-ozer/cc-devops-skills

### v0.1 — 초기 설정 (2026-03-08)
- [01-setup-handoff.md](archive/01-setup-handoff.md)
- 프로젝트 구조 생성 (skills, agents, configs, scripts, templates)
- install.sh / uninstall.sh / update.sh 작성
- clusters.yaml .gitignore 처리 + install.sh 자동 생성
- 보안 체크리스트 CLAUDE.md에 추가
- SSH 기반 git push 설정 (github-personal)
