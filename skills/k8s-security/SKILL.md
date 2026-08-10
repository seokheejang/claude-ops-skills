---
name: k8s-security
description: Kubernetes security posture audit - RBAC, NetworkPolicy, Pod Security, container config. Emits copy-paste read-only command bundles, then classifies findings by severity
argument-hint: "<cluster/context name>"
allowed-tools: Bash, Read, Grep, Glob
---

# K8s Security Skill

클러스터 보안 점검 전용. **READ-ONLY만** (`get`, `describe`, `auth can-i --list`). 개선 조치는 텍스트로만 안내.

## 실행 모델 — 명령은 내가, 실행은 사용자가

**클러스터에 직접 닿지 않는 것을 전제한다.** 시도해서 실패한 뒤 알아차리지 말고 처음부터 그렇게 움직인다.

- 감사는 데이터량이 많다. **원본 `-o json` 덤프를 그대로 요구하면 안 된다** — 아래처럼 위반 건만 뽑아내는 형태로 낸다
- `--context`를 **반드시 명시**한다. 컨텍스트를 모르면 그것부터 묻는다
- 한 번에 전부 내지 말고 **도메인 2~3개씩** 끊어서 낸다. 결과가 스크린샷으로 돌아오므로 한 화면에 담길 분량이어야 한다
- 돌아온 출력은 **실측**으로 다룬다. 단 어느 컨텍스트에서 나왔는지 불분명하면 그것부터 되묻는다
- **아직 안 돌린 도메인을 통과로 처리하지 않는다.** `(미확인)`으로 남긴다 — 보안 감사에서 미확인을 "이상 없음"으로 적는 건 거짓 보고다
- 예외: 사용자가 "직접 실행해봐"라고 하면 그때만 시도한다

## Arguments

`$ARGUMENTS` = 대상 컨텍스트 이름 → 아래 `CTX`에 그대로 넣는다. 인자가 없으면 `kubectl config get-contexts --no-headers -o name` 을 사용자에게 요청해 컨텍스트부터 확정한다. **추측해서 채우지 않는다.**

## Audit 묶음

도메인별로 나눠 낸다. 한 번에 전부 내지 말고 사용자가 감당할 단위(2~3개)씩.

```bash
CTX="<context>"        # ← 여기만 채우고 아래에서 필요한 블록 선택

# 1. RBAC — 와일드카드 권한 + cluster-admin 바인딩  (jq 필요: 배열 contains는 jsonpath로 불가)
kubectl --context $CTX get clusterroles -o json | jq -r '
  .items[] | select(.metadata.name | startswith("system:") | not)
  | select([.rules[]? | (.verbs + .resources + .apiGroups)] | flatten | index("*"))
  | .metadata.name'
kubectl --context $CTX get clusterrolebindings -o json | jq -r '
  .items[] | select(.roleRef.name=="cluster-admin")
  | select(.metadata.name | startswith("system:") | not)
  | "\(.metadata.name)\t\([.subjects[]?.name] | join(","))"'

# 2. NetworkPolicy — 정책 없는 네임스페이스
comm -23 <(kubectl --context $CTX get ns --no-headers -o custom-columns=:.metadata.name | sort) \
         <(kubectl --context $CTX get netpol -A --no-headers -o custom-columns=:.metadata.namespace | sort -u)

# 3. Pod Security — privileged / hostNetwork / 위험 capability
kubectl --context $CTX get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"\t"}{.spec.hostNetwork}{"\t"}{range .spec.containers[*]}{.securityContext.privileged}{","}{end}{"\n"}{end}' | grep -E 'true'

# 4. Container 설정 — limits 미설정 / latest 태그
kubectl --context $CTX get pods -A -o json | jq -r '
  .items[] as $p | $p.spec.containers[]
  | select((.image | endswith(":latest")) or (.image | contains(":") | not) or (.resources.limits == null))
  | "\($p.metadata.namespace)/\($p.metadata.name)\t\(.image)\tlimits=\(.resources.limits // "MISSING")"'

# 5. Service 노출 — LoadBalancer / NodePort
kubectl --context $CTX get svc -A --no-headers | grep -E 'LoadBalancer|NodePort'

# 6. ServiceAccount — automount 미차단 + default SA 사용
kubectl --context $CTX get pods -A -o jsonpath='{range .items[?(@.spec.serviceAccountName=="default")]}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}'
```

> 대규모 클러스터(Pod 수천개)는 `-A` 대신 `-n <ns>`로 네임스페이스를 나눠 낸다.

## Severity 분류

| 도메인 | [CRITICAL] | [WARNING] | [INFO] |
|--------|-----------|-----------|--------|
| RBAC | 와일드카드 권한(`system:` 제외), 비시스템 cluster-admin 바인딩 | secrets get/list, pods/exec 권한 | 미사용 RoleBinding |
| NetworkPolicy | 프로덕션 NS에 정책 없음 | 비시스템 NS 정책 없음, 전체 허용 정책 | Egress만 없음 |
| Pod Security | privileged, hostNetwork/PID/IPC, SYS_ADMIN/NET_ADMIN/ALL cap | runAsUser:0, readOnlyRootFS 미설정 | allowPrivilegeEscalation 미설정 |
| Container | — | limits/requests 미설정, probe 미설정, `:latest` | imagePullPolicy 미설정 |
| Secrets/SA | — | Secret env 노출(volume mount 권장), automountSAToken 미false, default SA 사용 | — |
| Service 노출 | — | LoadBalancer/NodePort/externalIPs | Ingress 경유 노출 |

## Output

어느 컨텍스트/점검시각 기준인지 명시. CRITICAL 최상단 경고. 도메인별 findings 나열 후 Summary 테이블(Domain/Critical/Warning/Info). 사용자가 아직 안 돌린 도메인은 `(미확인)`으로 남기고 통과로 처리하지 않는다. 이슈 없으면 "No issues found". 조치는 텍스트 안내.
