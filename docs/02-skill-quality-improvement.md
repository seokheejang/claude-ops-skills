# Skills & Agents 품질 개선

**날짜**: 2026-03-08
**범위**: 기존 4개 skill + 2개 agent SKILL.md/agent 정의 개선

## 배경

참고 repo 분석 결과:
- [wshobson/agents](https://github.com/wshobson/agents/tree/main/plugins/kubernetes-operations) — K8s manifest generator, security policies, helm scaffolding, gitops workflow
- [akin-ozer/cc-devops-skills](https://github.com/akin-ozer/cc-devops-skills/tree/main/devops-skills-plugin/skills) — 33개 DevOps skills, Generator/Validator 쌍 패턴

기존 SKILL.md가 명령어 나열 수준이었음 → 체계적 워크플로우로 개선 필요.

## 변경 내용

### Skills 공통 구조 적용

모든 SKILL.md에 아래 섹션 추가:
- **When to Use**: 언제 이 skill을 쓰는지
- **Step-by-Step Workflow**: 단계별 진단 가이드
- **Troubleshooting**: 증상별 대응 경로
- **판정 기준**: Warning/Critical 임계값 (해당 skill만)

### 변경 파일별 요약

| 파일 | 주요 추가 내용 |
|------|---------------|
| `skills/k8s-ops/SKILL.md` | 6단계 workflow, 증상별 Troubleshooting (CrashLoop, Pending, OOM, ImagePull, Service) |
| `skills/rpc-health/SKILL.md` | 5단계 workflow, Health Status 판정기준 (HEALTHY/WARNING/CRITICAL/DOWN), Multi-endpoint 비교 테이블 |
| `skills/ssh-ops/SKILL.md` | 6단계 workflow, Warning 임계값 테이블 (Load/Memory/Disk/Swap) |
| `skills/db-ops/SKILL.md` | 5단계 workflow (MySQL+PostgreSQL 각각), Troubleshooting (커넥션/락/슬로우쿼리) |
| `agents/k8s-debugger.md` | Investigation Protocol 6단계, Layer 판별 테이블, Symptom-based 진단경로, Output 템플릿 |
| `agents/rpc-monitor.md` | 5단계 Monitoring Protocol, Severity Levels, Report 템플릿 |

## 참고 repo에서 배운 패턴

### wshobson/agents
- 상세한 step-by-step workflow (10단계 이상)
- assets/references 디렉토리로 템플릿 분리
- Agent에 전문가 역할 부여 (kubernetes-architect)

### akin-ozer/cc-devops-skills
- Generator/Validator 쌍 패턴 (나중에 도입 고려)
- k8s-yaml-validator: 읽기 전용 검증, 6단계 파이프라인, severity별 리포트
- k8s-debug: 체계적 디버깅 (스크립트 포함)

## 미적용 사항 (향후 고려)

- Generator/Validator 패턴: 현재는 불필요, 필요시 추가
- 진단 스크립트 (cluster_health.sh 등): akin-ozer처럼 별도 스크립트 분리
- assets/references 디렉토리: 참조 문서/템플릿 분리
