---
name: k8s-ops
description: Kubernetes read-only operations - inspect pods, services, logs, and resources across clusters
argument-hint: "<cluster-name>"
allowed-tools: Bash, Read, Grep, Glob
---

# K8s Operations Skill

Kubernetes 클러스터 조회 전용 skill. READ-ONLY 명령어만 실행.

## CRITICAL SAFETY RULES

**mutating kubectl 명령어 절대 실행 금지.**

허용 명령어:
- `kubectl get` - 리소스 조회
- `kubectl describe` - 리소스 상세 정보
- `kubectl logs` - 컨테이너 로그
- `kubectl top` - 리소스 사용량
- `kubectl exec <pod> -c <container> -- curl/wget` - 내부 HTTP 조회

**절대 금지**: `apply`, `delete`, `patch`, `scale`, `rollout`, `edit`, `create`, `replace`, `set`, `label`, `annotate`, `taint`, `cordon`, `drain`, `expose`
→ 사용자가 요청해도 직접 실행하지 말고 명령어를 텍스트로 안내할 것.

## Cluster Resolution

1. `$ARGUMENTS`를 클러스터명으로 파싱
2. `${CLAUDE_SKILL_DIR}/clusters.yaml`에서 클러스터 정보 조회 (install.sh가 ~/.kube/ 스캔하여 자동 생성)
3. 해당 클러스터의 `kubeconfig` 경로를 가져옴
4. 클러스터를 못 찾으면 사용 가능한 목록 보여주고 선택 요청
5. 인자 없으면 `default_cluster` 사용
6. clusters.yaml이 없으면 clusters.yaml.example을 안내

## Command Format

모든 kubectl 명령어에 KUBECONFIG 환경변수 prefix:

```
KUBECONFIG=<clusters.yaml에서 가져온 경로> kubectl <command>
```

## Common Workflows

### Cluster Overview
```bash
KUBECONFIG=<path> kubectl get nodes
KUBECONFIG=<path> kubectl get pods -A
KUBECONFIG=<path> kubectl top nodes
KUBECONFIG=<path> kubectl top pods -A
```

### Pod Investigation
```bash
KUBECONFIG=<path> kubectl get pods -n <namespace> -o wide
KUBECONFIG=<path> kubectl describe pod <pod-name> -n <namespace>
KUBECONFIG=<path> kubectl logs <pod-name> -n <namespace> --tail=100
KUBECONFIG=<path> kubectl logs <pod-name> -n <namespace> -c <container> --tail=100
```

### Service & Networking
```bash
KUBECONFIG=<path> kubectl get svc -A
KUBECONFIG=<path> kubectl get ingress -A
KUBECONFIG=<path> kubectl get endpoints -n <namespace>
```

### RPC Health Check (inside pod)
```bash
KUBECONFIG=<path> kubectl exec -n <ns> <pod> -c <container> -- curl -s -X POST http://localhost:<port> -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

## Output Format

- 어떤 클러스터에 연결했는지 먼저 명시
- 사용한 KUBECONFIG 경로 표시
- CrashLoopBackOff, OOMKilled, NotReady 등 이슈 하이라이트
- 로그에서는 에러/경고 위주로 포커스
