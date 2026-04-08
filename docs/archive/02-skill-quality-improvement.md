# Skills & Agents 품질 개선

**날짜**: 2026-03-08 ~ 2026-03-09
**범위**: 기존 4개 skill + 2개 agent 개선, k8s-security skill + agent 신규 추가, cluster aliases 기능

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

## K8s Security Audit 추가 (2026-03-09)

### 설계 방향

기존 `rpc-health`(skill) / `rpc-monitor`(agent) 패턴과 동일한 2-tier 구조:
- **Skill** (`/k8s-security`): 빠른 보안 스캔 — 7개 도메인 데이터 수집
- **Agent** (`k8s-security-auditor`): 종합 감사 — 위험도 분석 + 상관관계 분석 + 개선 가이드

### 7개 보안 도메인

| Step | 도메인 | 주요 체크 항목 |
|------|--------|--------------|
| 1 | RBAC | 와일드카드 권한, cluster-admin 바인딩, secrets/exec 접근 |
| 2 | NetworkPolicy | NetworkPolicy 없는 NS, 전체 허용 정책 |
| 3 | Pod Security | privileged, hostNetwork/PID/IPC, 위험 capabilities |
| 4 | Container Config | resource limits, probes, latest 태그 |
| 5 | Secrets/SA | env 노출 secrets, automountServiceAccountToken, default SA |
| 6 | Services | LoadBalancer/NodePort 노출, externalIPs |
| 7 | Image Security | latest 태그, imagePullPolicy, 비신뢰 레지스트리 |

설계 포인트:
- Pod 데이터 1회 수집 → Step 3/4/5/7에서 재사용 (API 호출 최소화)
- `kube-system` 등 시스템 NS는 별도 섹션으로 분리 (false positive 방지)
- `k8s-ops`의 `clusters.yaml` 공유 (설정 중복 방지)

### Agent 6단계 워크플로우

1. Preflight → 2. Data Collection (`/k8s-security`) → 3. Risk Analysis (severity 부여) → 4. Correlation (도메인 간 복합 위험) → 5. Report → 6. Remediation (텍스트만)

### 신규/수정 파일

| 파일 | 변경 |
|------|------|
| `skills/k8s-security/SKILL.md` | 신규 — 7개 도메인 점검 skill |
| `agents/k8s-security-auditor.md` | 신규 — 6단계 감사 agent |
| `configs/claude.md.template` | `/k8s-security` 추가 |
| `README.md` | Skills/Agents 테이블, Cluster Aliases 섹션 추가 |

변경 불필요: `install.sh` (자동 탐색), `settings.json.template` (기존 allow 규칙 커버)

### 실전 테스트 결과

dev 클러스터에서 테스트한 결과:

| 항목 | Critical | Warning | 핵심 발견 |
|------|----------|---------|----------|
| RBAC | 2 | 3 | CD 시스템 ClusterRole에 full wildcard 권한 |
| NetworkPolicy | 1 | 0 | **클러스터 전체 NetworkPolicy 0건** |
| Pod Security | 1 | 0 | 디버그 pod가 hostNetwork/PID/IPC 전체 활성화 상태로 방치 |
| Container Config | 0 | 3 | 다수 컨테이너 resource limits 미설정 |
| Secrets/SA | 0 | 3 | 다수 pod가 default SA 사용, secrets env 노출 |

핵심 위험: NetworkPolicy 전무 + 디버그 pod 방치 = 앱 취약점 → 디버그 pod → kubelet API → 전체 노드 장악 경로

## Cluster Aliases 기능 (2026-03-09)

### 동기

`/k8s-ops my-long-cluster-name` 전체 이름 입력이 번거로움. 짧은 alias 매핑 필요. 단, 실제 클러스터명은 `clusters.yaml`(gitignore)에만 존재 → public repo 노출 방지.

### 구현

`clusters.yaml`에 `aliases` 배열 추가:
```yaml
clusters:
  my-cluster:
    aliases: ["dev", "my dev"]   # /k8s-ops dev → my-cluster
```

매칭 우선순위: 키 이름 정확 일치 > aliases 일치 > 부분 매칭 (후보 복수면 선택 요청)

수정 파일: `clusters.yaml.example`, `k8s-ops/SKILL.md`, `k8s-security/SKILL.md` Cluster Resolution 섹션

## 미적용 사항 (향후 고려)

- Generator/Validator 패턴: 현재는 불필요, 필요시 추가
- 진단 스크립트 (cluster_health.sh 등): akin-ozer처럼 별도 스크립트 분리
- assets/references 디렉토리: 참조 문서/템플릿 분리
