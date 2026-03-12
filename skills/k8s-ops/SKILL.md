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
- `kubectl exec <pod> -- df/du/ls/stat/find/cat` - 파일시스템 조회 (스토리지 점검용)
- `kubectl get --raw` - API 직접 호출 (kubelet stats 등)

**절대 금지**: `apply`, `delete`, `patch`, `scale`, `rollout`, `edit`, `create`, `replace`, `set`, `label`, `annotate`, `taint`, `cordon`, `drain`, `expose`
→ 사용자가 요청해도 직접 실행하지 말고 명령어를 텍스트로 안내할 것.

## When to Use

- 클러스터 전체 상태 점검이 필요할 때
- 특정 Pod/Service/Node에 문제가 있을 때
- 로그를 확인하고 싶을 때
- 리소스 사용량(CPU/메모리)을 확인할 때
- PV/PVC 디스크 사용량을 확인할 때
- K8s 내부 RPC 엔드포인트를 조회할 때

## Cluster Resolution

1. `$ARGUMENTS`를 클러스터명으로 파싱
2. `${CLAUDE_SKILL_DIR}/clusters.yaml`에서 클러스터 정보 조회 (install.sh가 ~/.kube/ 스캔하여 자동 생성)
3. 매칭 우선순위:
   a. 클러스터 키 이름과 정확히 일치 (예: `my-cluster`)
   b. `aliases` 배열에 포함된 값과 일치 (예: `dev`, `my dev`)
   c. 부분 매칭 시 후보가 여러 개면 목록 보여주고 선택 요청
4. 해당 클러스터의 `kubeconfig` 경로를 가져옴
5. 클러스터를 못 찾으면 사용 가능한 목록 보여주고 선택 요청
6. 인자 없으면 `default_cluster` 사용
7. clusters.yaml이 없으면 clusters.yaml.example을 안내

## Command Format

모든 kubectl 명령어에 KUBECONFIG 환경변수 prefix:

```
KUBECONFIG=<clusters.yaml에서 가져온 경로> kubectl <command>
```

## Step-by-Step Workflow

### Step 1: 클러스터 연결 확인
```bash
KUBECONFIG=<path> kubectl get nodes -o wide
```
- 모든 노드가 Ready인지 확인
- NotReady 노드가 있으면 즉시 보고

### Step 2: 클러스터 전체 개요
```bash
KUBECONFIG=<path> kubectl get pods -A --sort-by='.status.startTime'
KUBECONFIG=<path> kubectl top nodes
KUBECONFIG=<path> kubectl top pods -A --sort-by=memory
```
- 비정상 상태 Pod 우선 식별 (CrashLoopBackOff, Pending, Error, OOMKilled)
- 노드 리소스 압박 여부 확인

### Step 2.5: 스토리지 사용량 점검

#### 2.5.1 PVC 전체 현황
```bash
KUBECONFIG=<path> kubectl get pvc -A -o wide
```
- Bound/Pending/Lost 상태 확인
- Pending PVC가 있으면 즉시 보고

#### 2.5.2 PV 사용량 확인 (kubelet stats API)
```bash
# 각 노드별 PV 사용량 조회
KUBECONFIG=<path> kubectl get --raw /api/v1/nodes/<node>/proxy/stats/summary
```
- 응답의 `pods[].volume[]`에서 `capacityBytes`, `usedBytes`, `availableBytes` 추출
- 사용률(%) 계산하여 정렬

> **참고**: `local-path` 등 일부 StorageClass는 kubelet stats에 사용량이 보고되지 않을 수 있다. 이 경우 2.5.3으로 대체.

#### 2.5.3 kubelet stats 미지원 시 — 호스트 경로 직접 확인
```bash
# PV의 호스트 경로 확인
KUBECONFIG=<path> kubectl describe pv <pv-name> | grep Path:
# 해당 노드에서 호스트 파일시스템 접근 가능한 pod 찾기 (node-exporter 등)
KUBECONFIG=<path> kubectl get pods -A -o wide --field-selector spec.nodeName=<node> | grep node-exporter
# du/df로 실제 사용량 확인
KUBECONFIG=<path> kubectl exec -n <ns> <node-exporter-pod> -- df -h <host-mount-path>/<pv-path>
KUBECONFIG=<path> kubectl exec -n <ns> <node-exporter-pod> -- du -sh <host-mount-path>/<pv-path>
```

#### 2.5.4 임계치 기반 상세 분석 (70% 이상)

사용률 70% 이상인 PVC에 대해 자동으로 상세 분석 수행:

1. **디렉토리별 사용량 분석**
   ```bash
   kubectl exec -n <ns> <node-exporter-pod> -- du -sh <pv-path>/*
   ```

2. **연결된 워크로드 식별**
   ```bash
   kubectl get pods -A -o json | jq '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName == "<pvc-name>")'
   ```

3. **증가 추세 판단**
   - 가장 오래된/최신 파일 타임스탬프 확인
   - 데이터 보존 설정(retention) 존재 여부 확인

**임계치별 표시**:
- 70~85%: **[WARNING]** — 모니터링 권장
- 85~95%: **[HIGH]** — 조치 필요
- 95%+: **[CRITICAL]** — 즉시 조치 필요

### Step 3: 문제 워크로드 식별
```bash
# 비정상 Pod만 필터링
KUBECONFIG=<path> kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
# 최근 이벤트 확인
KUBECONFIG=<path> kubectl get events -A --sort-by='.lastTimestamp' | tail -30
```

### Step 4: 상세 조사
```bash
KUBECONFIG=<path> kubectl describe pod <pod-name> -n <namespace>
KUBECONFIG=<path> kubectl logs <pod-name> -n <namespace> --tail=100
KUBECONFIG=<path> kubectl logs <pod-name> -n <namespace> -c <container> --tail=100
# 이전 컨테이너 로그 (CrashLoop인 경우)
KUBECONFIG=<path> kubectl logs <pod-name> -n <namespace> --previous --tail=100
```

### Step 5: 네트워크 및 서비스 확인
```bash
KUBECONFIG=<path> kubectl get svc -A
KUBECONFIG=<path> kubectl get ingress -A
KUBECONFIG=<path> kubectl get endpoints -n <namespace>
```

### Step 6: RPC 내부 헬스체크 (블록체인 노드용)
```bash
KUBECONFIG=<path> kubectl exec -n <ns> <pod> -c <container> -- curl -s -X POST http://localhost:<port> \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

## Troubleshooting Guide

### Pod CrashLoopBackOff
1. `kubectl describe pod` → Events 섹션에서 원인 확인
2. `kubectl logs --previous` → 이전 컨테이너의 크래시 로그 확인
3. Exit Code 확인: 137=OOMKilled, 1=애플리케이션 에러, 139=Segfault
4. 리소스 제한 확인 (메모리 limits가 너무 낮은지)

### Pod Pending
1. `kubectl describe pod` → Events에서 스케줄링 실패 원인 확인
2. `kubectl get nodes` → 가용 노드 확인
3. `kubectl top nodes` → 리소스 여유 확인
4. nodeSelector, tolerations, affinity 설정 확인
5. PVC가 있으면 PV 바인딩 상태 확인

### OOMKilled (Exit Code 137)
1. `kubectl describe pod` → Last State에서 메모리 사용량 확인
2. `kubectl top pod` → 현재 메모리 사용량 확인
3. resources.limits.memory 값 확인
4. 해결: limits 증가 또는 애플리케이션 메모리 최적화 (텍스트로 안내)

### ImagePullBackOff
1. `kubectl describe pod` → Events에서 이미지명/태그 확인
2. 이미지가 존재하는지, 태그가 맞는지 확인
3. Private registry인 경우 imagePullSecrets 설정 확인

### Service 접속 불가
1. `kubectl get endpoints <svc>` → 엔드포인트가 있는지 확인 (비어있으면 selector 불일치)
2. `kubectl get pods -l <selector>` → 매칭되는 Pod 확인
3. Pod가 Ready인지, containerPort와 service targetPort 일치하는지 확인
4. NetworkPolicy가 트래픽을 차단하는지 확인

### PVC 용량 부족
1. `kubectl get pvc` → 용량 및 StorageClass 확인
2. kubelet stats 또는 du로 실제 사용량 확인
3. 연결된 Pod의 데이터 보존 정책(retention) 확인
4. 해결: PVC 확장, retention 단축, 불필요 데이터 정리 (텍스트로 안내)
5. `local-path` StorageClass는 quota enforcement가 없어 할당량 초과 가능 — 호스트 디스크 전체 사용률도 함께 확인

## Output Format

- 어떤 클러스터에 연결했는지 먼저 명시
- 사용한 KUBECONFIG 경로 표시
- 비정상 상태는 **굵게** 또는 경고 표시로 하이라이트
- CrashLoopBackOff, OOMKilled, NotReady 등 이슈를 최상단에 요약
- 로그에서는 에러/경고 위주로 포커스
- 조치가 필요한 경우 실행할 명령어를 텍스트로 안내 (직접 실행 금지)
- PVC 사용량은 테이블 형태로 표시 (PVC명, Namespace, 용량, 사용량, 사용률, 상태)
- 70% 이상 PVC는 **[WARNING]**, **[HIGH]**, **[CRITICAL]** 태그와 함께 상세 분석 결과 포함
