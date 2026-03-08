# Changelog

claude-ops-skills 작업 이력 및 다음 작업 관리.
세부 내용은 각 문서 링크 참조.

## 작업 이력

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
- [ ] **K8s 보안 agent**: 클러스터 보안 점검 자동화 (RBAC, NetworkPolicy, PodSecurity 등 감사)
- [ ] **Helm Generator/Validator**: Helm chart 생성 + 검증 skill 쌍
- [ ] **Terraform Generator/Validator**: Terraform 코드 생성 + plan 검증 skill 쌍
- [ ] **Generator/Validator 패턴 도입**: 필요시 k8s-yaml-validator 등 추가
- [ ] **프로젝트별 skill 적용**: 다른 프로젝트 repo에 `.claude/skills/` 추가 테스트
- [ ] **새 skill 후보**: promql-generator, log-search, infra-report 등

### 낮은 우선순위
- [ ] **install.sh 개선**: clusters.yaml 생성 시 kubeconfig validation 추가
- [ ] **settings.local.json 정리 스크립트**: 중복 규칙 자동 제거
- [ ] **zshrc alias**: 자주 쓰는 조합 단축키 추가
