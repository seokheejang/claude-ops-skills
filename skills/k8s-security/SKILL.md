---
name: k8s-security
description: Kubernetes security posture check - RBAC, NetworkPolicy, Pod Security, container config audit
argument-hint: "<cluster-name>"
allowed-tools: Bash, Read, Grep, Glob
---

# K8s Security Skill

Kubernetes 클러스터 보안 점검 전용 skill. READ-ONLY 명령어만 실행.

## Safety: READ-ONLY

허용: get, describe, `auth can-i --list`.
금지: apply, delete, patch, scale, rollout, edit, create, replace, set, label, annotate, taint, cordon, drain, expose.
개선 필요시 명령어를 텍스트로 안내.

## Cluster Resolution

`$ARGUMENTS` → `${CLAUDE_SKILL_DIR}/../k8s-ops/clusters.yaml`에서 매칭 (정확→alias→부분). 미매칭시 목록 표시. 인자 없으면 default_cluster. 모든 명령어에 `KUBECONFIG=<path>` prefix.

## Audit Domains

7개 보안 도메인 순차 점검. Severity: **[CRITICAL]** 즉시 조치 / **[WARNING]** 계획적 개선 / **[INFO]** 검토 필요.

| 도메인 | 명령어 | 점검 항목 |
|--------|--------|-----------|
| RBAC | `get clusterroles/clusterrolebindings/roles/rolebindings -o json` | [C] 와일드카드 권한(system: 제외), cluster-admin 비시스템 바인딩 / [W] secrets get/list, pods/exec 권한 / [I] 미사용 RoleBinding |
| NetworkPolicy | `get namespaces -o json`, `get networkpolicies -A -o json` | [C] 프로덕션 NS에 정책 없음 / [W] 비시스템 NS 정책 없음, 전체 허용 정책 / [I] Egress만 없음 |
| Pod Security | `get pods -A -o json` | [C] privileged, hostNetwork/PID/IPC, SYS_ADMIN/NET_ADMIN/ALL cap / [W] runAsUser:0, readOnlyRootFS 미설정 / [I] allowPrivilegeEscalation 미설정 |
| Container 설정 | (Pod 데이터 재사용) | [W] limits/requests 미설정, probes 미설정, :latest 태그 / [I] imagePullPolicy |
| Secrets/SA | `get serviceaccounts -A -o json` + Pod 데이터 | [W] Secret env 노출(volume mount 권장), automountSAToken 미false, default SA 사용 |
| Service 노출 | `get services -A -o json` | [W] LoadBalancer/NodePort/externalIPs 서비스 / [I] Ingress 경유 노출 |
| Image Security | (Pod 데이터 재사용) | [W] :latest/태그없음, imagePullPolicy 미설정 / [I] 외부 registry 이미지 |

> 대규모 클러스터: Pod 수천개시 네임스페이스별 분할 조회 권장.

## Output

클러스터/KUBECONFIG/점검시간 명시. 도메인별 findings 나열. CRITICAL 최상단 경고. Summary 테이블(Domain/Critical/Warning/Info). 이슈 없으면 "No issues found". 조치는 텍스트 안내.
