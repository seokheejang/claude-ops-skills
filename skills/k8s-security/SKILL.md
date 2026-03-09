---
name: k8s-security
description: Kubernetes security posture check - RBAC, NetworkPolicy, Pod Security, container config audit
argument-hint: "<cluster-name>"
allowed-tools: Bash, Read, Grep, Glob
---

# K8s Security Skill

Kubernetes 클러스터 보안 점검 전용 skill. READ-ONLY 명령어만 실행하여 보안 취약점을 식별.

## CRITICAL SAFETY RULES

**mutating kubectl 명령어 절대 실행 금지.**

허용 명령어:
- `kubectl get` - 리소스 조회
- `kubectl describe` - 리소스 상세 정보
- `kubectl auth can-i --list` - RBAC 권한 조회

**절대 금지**: `apply`, `delete`, `patch`, `scale`, `rollout`, `edit`, `create`, `replace`, `set`, `label`, `annotate`, `taint`, `cordon`, `drain`, `expose`
→ 개선이 필요한 경우 실행할 명령어를 텍스트로 안내할 것.

## When to Use

- 클러스터 보안 상태를 빠르게 점검할 때
- RBAC 권한이 과도하게 부여되었는지 확인할 때
- NetworkPolicy 적용 범위를 확인할 때
- 컨테이너가 보안 모범사례를 따르는지 확인할 때
- 정기 보안 감사 데이터를 수집할 때

## Cluster Resolution

1. `$ARGUMENTS`를 클러스터명으로 파싱
2. `${CLAUDE_SKILL_DIR}/../k8s-ops/clusters.yaml`에서 클러스터 정보 조회
3. 매칭 우선순위:
   a. 클러스터 키 이름과 정확히 일치 (예: `my-cluster`)
   b. `aliases` 배열에 포함된 값과 일치 (예: `dev`, `my dev`)
   c. 부분 매칭 시 후보가 여러 개면 목록 보여주고 선택 요청
4. 해당 클러스터의 `kubeconfig` 경로를 가져옴
5. 클러스터를 못 찾으면 사용 가능한 목록 보여주고 선택 요청
6. 인자 없으면 `default_cluster` 사용
7. clusters.yaml이 없으면 `k8s-ops/clusters.yaml.example`을 안내

## Command Format

모든 kubectl 명령어에 KUBECONFIG 환경변수 prefix:

```
KUBECONFIG=<clusters.yaml에서 가져온 경로> kubectl <command>
```

## Audit Domains

7개 보안 도메인을 순차 점검. 각 항목에 severity를 부여:
- **[CRITICAL]**: 즉시 조치 필요한 보안 위험
- **[WARNING]**: 보안 모범사례 위반, 계획적 개선 필요
- **[INFO]**: 검토 필요하나 의도적일 수 있는 설정

### Step 1: RBAC 감사

```bash
KUBECONFIG=<path> kubectl get clusterroles -o json
KUBECONFIG=<path> kubectl get clusterrolebindings -o json
KUBECONFIG=<path> kubectl get roles -A -o json
KUBECONFIG=<path> kubectl get rolebindings -A -o json
```

**점검 항목:**
- [CRITICAL] 와일드카드 권한 (`verbs: ["*"]` 또는 `resources: ["*"]`) 보유 ClusterRole (system: 접두사 제외)
- [CRITICAL] `cluster-admin` ClusterRoleBinding이 시스템 계정이 아닌 사용자/그룹에 바인딩됨
- [WARNING] `secrets`, `configmaps` 리소스에 대한 get/list/watch 권한 보유 Role
- [WARNING] `pods/exec` 권한을 가진 Role
- [INFO] 사용되지 않는 것으로 보이는 RoleBinding (바인딩 대상 ServiceAccount가 존재하지 않음)

### Step 2: NetworkPolicy 커버리지

```bash
KUBECONFIG=<path> kubectl get namespaces -o json
KUBECONFIG=<path> kubectl get networkpolicies -A -o json
```

**점검 항목:**
- [CRITICAL] 프로덕션 네임스페이스에 NetworkPolicy가 하나도 없음
- [WARNING] 비시스템 네임스페이스(`kube-system`, `kube-public`, `kube-node-lease` 제외)에 NetworkPolicy 없음
- [WARNING] 전체 허용 정책: `podSelector: {}` + ingress/egress에 `from: [{}]` 또는 `to: [{}]`
- [INFO] Egress 정책 없이 Ingress 정책만 있는 네임스페이스

### Step 3: Pod Security

```bash
KUBECONFIG=<path> kubectl get pods -A -o json
```

**점검 항목 (kube-system 네임스페이스는 별도 섹션으로 분리):**
- [CRITICAL] `securityContext.privileged: true`
- [CRITICAL] `hostNetwork: true`, `hostPID: true`, `hostIPC: true` (비시스템 Pod)
- [CRITICAL] `capabilities.add`에 `SYS_ADMIN`, `NET_ADMIN`, `ALL` 포함
- [WARNING] `securityContext.runAsUser: 0` 또는 `runAsNonRoot` 미설정
- [WARNING] `securityContext.readOnlyRootFilesystem` 미설정
- [INFO] `allowPrivilegeEscalation` 미설정 (기본값 true)

> **대규모 클러스터 참고**: Pod이 수천 개인 경우 네임스페이스별로 분할 조회 권장:
> `kubectl get pods -n <namespace> -o json`

### Step 4: Container 설정

Step 3에서 수집한 Pod 데이터를 재사용하여 분석.

**점검 항목:**
- [WARNING] `resources.limits` 미설정 (CPU 또는 memory)
- [WARNING] `resources.requests` 미설정
- [WARNING] `readinessProbe` 또는 `livenessProbe` 미설정
- [WARNING] 이미지 태그가 `:latest`이거나 태그 없음
- [INFO] `imagePullPolicy`가 `Always`가 아닌 경우 (`:latest` 태그 사용 시)

### Step 5: Secrets & ServiceAccount

```bash
KUBECONFIG=<path> kubectl get serviceaccounts -A -o json
```
+ Step 3의 Pod 데이터 재사용.

**점검 항목:**
- [WARNING] Secret이 `env[].valueFrom.secretKeyRef`로 환경변수에 직접 노출 (volume mount 권장)
- [WARNING] `automountServiceAccountToken`이 명시적으로 `false`가 아닌 비시스템 Pod
- [WARNING] `default` ServiceAccount를 사용하는 Pod (전용 SA 권장)
- [INFO] ServiceAccount에 과도한 Role이 바인딩되어 있는 경우

### Step 6: Service 노출

```bash
KUBECONFIG=<path> kubectl get services -A -o json
```

**점검 항목:**
- [WARNING] `type: LoadBalancer` 서비스 (의도적인지 검토 필요)
- [WARNING] `type: NodePort` 서비스 (외부 노출 검토 필요)
- [WARNING] `externalIPs`가 설정된 서비스
- [INFO] ClusterIP 서비스 중 외부 Ingress를 통해 노출되는 서비스

### Step 7: Image Security

Step 3의 Pod 데이터를 재사용하여 분석.

**점검 항목:**
- [WARNING] 이미지에 태그가 없거나 `:latest` 사용
- [WARNING] `:latest` 태그 사용 시 `imagePullPolicy: Always` 미설정
- [INFO] 알려진 private registry가 아닌 외부 이미지 사용

## Output Format

```
## K8s Security Check: <cluster-name>

**KUBECONFIG**: <path>
**점검 시간**: <timestamp>

### 1. RBAC
- [CRITICAL] ClusterRoleBinding "xxx" grants cluster-admin to user "dev-user"
- [WARNING] ClusterRole "custom-role" has wildcard verbs on secrets

### 2. NetworkPolicy
- [WARNING] Namespace "app" has no NetworkPolicies (pods: 12)
- [WARNING] Namespace "staging" has no NetworkPolicies (pods: 5)

### 3. Pod Security
- [CRITICAL] Pod "debug-pod" in "default" runs as privileged
- [WARNING] 8 pods running as root (runAsNonRoot not set)

### 4. Container Config
- [WARNING] 15 containers without resource limits
- [WARNING] 7 containers without readiness/liveness probes

### 5. Secrets & ServiceAccount
- [WARNING] 3 pods expose secrets via environment variables
- [WARNING] 22 pods use default ServiceAccount

### 6. Services
- [WARNING] 2 LoadBalancer services found
- [INFO] 1 NodePort service: "debug-svc" in "default"

### 7. Image Security
- [WARNING] 5 containers using :latest tag

### Summary

| Domain          | Critical | Warning | Info |
|-----------------|----------|---------|------|
| RBAC            | 1        | 1       | 0    |
| NetworkPolicy   | 0        | 2       | 0    |
| Pod Security    | 1        | 1       | 0    |
| Container Config| 0        | 2       | 0    |
| Secrets/SA      | 0        | 2       | 0    |
| Services        | 0        | 1       | 1    |
| Image Security  | 0        | 1       | 0    |
| **Total**       | **2**    | **10**  | **1**|
```

- 비정상 항목이 없으면 각 도메인에 "✅ No issues found" 표시
- CRITICAL 항목이 있으면 최상단에 별도 경고 블록으로 강조
- 조치가 필요한 경우 개선 명령어를 텍스트로 안내 (직접 실행 금지)
