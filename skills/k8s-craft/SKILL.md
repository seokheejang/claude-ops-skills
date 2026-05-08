---
name: k8s-craft
description: Author and design Kubernetes manifests — workloads, networking, storage, RBAC, NetworkPolicy, cost optimization, operators, service mesh, multi-cluster. Use when the user wants to create, design, write, scaffold, or review YAML manifests, asks "manifest 만들어줘", "K8s 설계", "deployment YAML", "RBAC 작성", or needs Helm/operator/mesh patterns. Read-only paired with k8s-ops (which handles inspection and troubleshooting).
argument-hint: "<resource type or design topic>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# k8s-craft

K8s 리소스 작성/설계 가이드 스킬. **manifest 파일 출력 + 명령어 텍스트 안내만** 한다.
조회/디버깅/트러블슈팅은 [k8s-ops](../k8s-ops/) 사용.

상세 패턴은 [references/](references/) 참조.

## Safety Rules

**kubectl 변경 명령어 직접 실행 절대 금지** — 글로벌 CLAUDE.md 규칙.

| 동작 | 허용 여부 |
|------|----------|
| YAML manifest 파일 출력 (Write) | ✅ |
| `kubectl apply --dry-run=client/server` 검증 | ✅ |
| `kubectl explain <resource>` | ✅ |
| `kubeval`, `kustomize build`, `helm template` | ✅ |
| `kubectl apply / create / replace / patch / edit / scale / delete / rollout restart / cordon / drain` | ❌ |
| 사용자가 적용 요청 시 → 명령어를 텍스트로 안내, 실행 X | 필수 |

manifest 작성 후 사용자에게 적용 명령어를 안내. 실행은 사용자 책임.

## Workflow

1. **요구사항 파악** — 워크로드 종류, 스케일링, 보안 요구사항, 의존성
2. **참조 로드** — 아래 Reference Guide에서 해당 토픽 reference 파일 읽음
3. **manifest 초안 작성** — `docs/k8s/<name>.yaml` 또는 사용자 지정 경로
4. **검증** — `kubectl apply --dry-run=client -f <file>` 또는 `kubeval`
5. **적용 안내** — 검증 통과한 명령어를 사용자에게 텍스트로 제공

## Reference Guide

토픽별 상세 패턴. 작업 컨텍스트에 따라 해당 파일을 로드한다.

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Workloads | [references/workloads.md](references/workloads.md) | Deployment, StatefulSet, DaemonSet, Job, CronJob 작성 |
| Networking | [references/networking.md](references/networking.md) | Service, Ingress, NetworkPolicy 작성 |
| Configuration | [references/configuration.md](references/configuration.md) | ConfigMap, Secret, env 주입 |
| Storage | [references/storage.md](references/storage.md) | PV, PVC, StorageClass, CSI 작성 |
| Cost Optimization | [references/cost-optimization.md](references/cost-optimization.md) | resource limits, VPA, HPA, spot, right-sizing |
| Custom Operators | [references/custom-operators.md](references/custom-operators.md) | CRD, Operator SDK, controller-runtime |
| Service Mesh | [references/service-mesh.md](references/service-mesh.md) | Istio, Linkerd, traffic management, mTLS |
| Multi-Cluster | [references/multi-cluster.md](references/multi-cluster.md) | Cluster API, federation, cross-cluster |

## MUST DO

- Declarative YAML manifest 사용 (imperative kubectl 명령어 회피)
- 모든 컨테이너에 resource requests/limits 설정
- liveness/readiness probe 포함
- Secret으로 민감 정보 (ConfigMap에 비밀번호 X)
- 최소 권한 RBAC (Role/RoleBinding 우선, ClusterRole 신중)
- NetworkPolicy로 네트워크 분리
- Namespace로 논리적 격리
- 일관된 라벨링 (`app`, `version`, `tier`)

## MUST NOT DO

- 프로덕션에 resource limits 없이 배포
- ConfigMap에 secret 저장
- 기본 ServiceAccount를 애플리케이션 Pod에 사용
- 무제한 네트워크 접근 (default allow-all)
- 정당화 없는 root 컨테이너
- liveness/readiness probe 생략
- 프로덕션 이미지에 `latest` 태그
- 불필요한 포트/서비스 노출

## Output

- 파일 경로: 사용자 지정 또는 `docs/k8s/<resource>-<name>.yaml`
- manifest는 단독 yaml 파일로
- 멀티 리소스는 `---` 구분자
- 적용 명령어 텍스트 안내 (실행 X)
- 설계 결정 근거 1~2줄 요약

원본: github.com/Jeffallan/claude-skills (MIT) — 우리 컨벤션에 맞게 customize.
