# Changelog

claude-ops-skills 작업 이력 및 다음 작업 관리.
세부 내용은 각 문서 링크 참조.

## 작업 이력

### v0.5 — GitHub Actions Security Check (2026-03-09)
- `.github/workflows/security-check.yml` 추가: PR/push 시 자동 보안 검사
- 6개 체크 항목: 금지 파일, 개인 경로, credential, skill 구조, mutating kubectl, 하드코딩 IP
- CLAUDE.md 보안 체크리스트를 CI로 자동화

### v0.4 — K8s Security Audit + Cluster Aliases (2026-03-09)
- [02-skill-quality-improvement.md](02-skill-quality-improvement.md) (K8s Security Audit / Cluster Aliases 섹션)
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
- [02-skill-quality-improvement.md](02-skill-quality-improvement.md)
- 4개 skill SKILL.md 체계적 워크플로우로 개선 (When to Use, Step-by-Step, Troubleshooting, 판정 기준)
- 2개 agent 정의 강화 (Investigation Protocol, Severity Levels, Report Format)
- 참고: wshobson/agents, akin-ozer/cc-devops-skills

### v0.1 — 초기 설정 (2026-03-08)
- [01-setup-handoff.md](01-setup-handoff.md)
- 프로젝트 구조 생성 (skills, agents, configs, scripts, templates)
- install.sh / uninstall.sh / update.sh 작성
- clusters.yaml .gitignore 처리 + install.sh 자동 생성
- 보안 체크리스트 CLAUDE.md에 추가
- SSH 기반 git push 설정 (github-personal)

## 다음 작업 후보 (Backlog)

### 우선순위 높음
- [ ] **skill 실전 테스트**: 각 skill을 실제 운영 환경에서 호출하여 워크플로우 검증
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
- [ ] **install.sh 개선**: clusters.yaml 생성 시 kubeconfig validation 추가
- [ ] **settings.local.json 정리 스크립트**: 중복 규칙 자동 제거
- [ ] **zshrc alias**: 자주 쓰는 조합 단축키 추가
