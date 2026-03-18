---
name: k8s-ops
description: Kubernetes read-only operations - inspect pods, services, logs, and resources across clusters
argument-hint: "<cluster-name>"
allowed-tools: Bash, Read, Grep, Glob
---

# K8s Operations Skill

Kubernetes 클러스터 조회 전용 skill. READ-ONLY 명령어만 실행.

## Safety: READ-ONLY

허용: get, describe, logs, top, exec(curl/wget/df/du/ls/stat/find/cat 조회), `get --raw`.
금지: apply, delete, patch, scale, rollout, edit, create, replace, set, label, annotate, taint, cordon, drain, expose.
변경 필요시 명령어를 텍스트로 안내.

## Cluster Resolution

`$ARGUMENTS` → `${CLAUDE_SKILL_DIR}/clusters.yaml`에서 매칭 (정확→alias→부분). 미매칭시 목록 표시. 인자 없으면 default_cluster. clusters.yaml 없으면 clusters.yaml.example 안내. 모든 명령어에 `KUBECONFIG=<path>` prefix.

## Workflow

| 단계 | 명령어 | 확인 사항 |
|------|--------|-----------|
| 연결 | `kubectl get nodes -o wide` | NotReady 노드 즉시 보고 |
| 전체 개요 | `get pods -A --sort-by=.status.startTime`, `top nodes`, `top pods -A --sort-by=memory` | 비정상 Pod (CrashLoop/Pending/Error/OOMKilled), 리소스 압박 |
| PVC 현황 | `get pvc -A -o wide` | Pending/Lost PVC 즉시 보고 |
| PV 사용량 | `get --raw /api/v1/nodes/<node>/proxy/stats/summary` | capacityBytes/usedBytes에서 사용률(%) 계산 |
| PV fallback | `describe pv` → Path 확인, node-exporter pod에서 `df -h`/`du -sh` | local-path 등 kubelet stats 미지원시 |
| 문제 워크로드 | `get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded`, `get events -A --sort-by=.lastTimestamp \| tail -30` | 비정상 Pod + 최근 이벤트 |
| 상세 조사 | `describe pod`, `logs --tail=100`, `logs -c <container> --tail=100`, `logs --previous` | 에러/크래시 원인 |
| 네트워크 | `get svc -A`, `get ingress -A`, `get endpoints` | endpoint 비어있는지 |
| RPC 헬스체크 | `exec <pod> -c <container> -- curl -s -X POST localhost:<port>` | eth_blockNumber 등 |

### PVC 임계치 (70%+ 자동 상세분석)

- 70~85%: **[WARNING]** — 모니터링 권장
- 85~95%: **[HIGH]** — 조치 필요
- 95%+: **[CRITICAL]** — 즉시 조치 필요

70%+ PVC: `du -sh <path>/*`로 디렉토리별 분석, 연결 워크로드 식별, 파일 타임스탬프로 증가 추세 판단, retention 설정 확인.

## Troubleshooting

- **CrashLoop**: describe→Events, `logs --previous`, exit code (137=OOM, 1=app, 139=segfault), limits 확인
- **Pending**: describe→Events, 노드 가용성, nodeSelector/tolerations/affinity, PVC 바인딩
- **OOMKilled(137)**: `top pod` → 메모리 확인, limits 검토
- **ImagePullBackOff**: describe→이미지명/태그, imagePullSecrets
- **Svc 접속불가**: `get endpoints` 비어있으면 selector 불일치, Pod Ready/containerPort=targetPort 확인, NetworkPolicy
- **PVC 부족**: kubelet stats 또는 du, retention 정책. local-path는 quota 없음 — 호스트 디스크도 확인

## Output

클러스터/KUBECONFIG 명시. 비정상 항목 최상단 요약. PVC는 테이블(PVC/NS/용량/사용량/사용률/상태). severity 태그. 조치는 텍스트 안내.
