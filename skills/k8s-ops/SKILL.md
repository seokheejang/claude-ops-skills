---
name: k8s-ops
description: Kubernetes read-only inspection - emits copy-paste kubectl command bundles for the operator to run, then interprets the pasted output
argument-hint: "<cluster/context name>"
allowed-tools: Bash, Read, Grep, Glob
---

# K8s Operations Skill

Kubernetes 조회 전용. **READ-ONLY만.** 변경 명령(`apply/delete/patch/scale/rollout/edit/create/replace/set/label/annotate/taint/cordon/drain/expose`)은 어떤 상황에서도 실행하지 않는다 — 필요하면 텍스트로만 안내.

## 실행 모델 — 명령은 내가, 실행은 사용자가

**이 환경에서 클러스터에 직접 닿지 않는 것을 전제한다.** 시도해서 실패한 뒤 알아차리지 말고 처음부터 그렇게 움직인다.

- 필요한 조회를 **한 번에 묶어** 복붙 가능한 블록 하나로 낸다. 한 줄씩 찔끔 요청하지 않는다
- `--context <name>`을 **반드시 명시**한다. 컨텍스트를 모르면 그것부터 묻는다
- 결과가 **스크린샷으로 돌아오므로 화면에 담기게 줄인다** — `--no-headers`, `-o jsonpath`, `| head -n`, `| grep`, `--sort-by`로 필요한 필드만
- 돌아온 출력은 **실측**으로 다룬다. 단 어느 컨텍스트/네임스페이스에서 나왔는지 불분명하면 그것부터 되묻는다
- 확인 못 한 것은 `(미확인)`으로 남긴다. **추측으로 메우지 않는다.** 그 답에 의존하지 않는 분석을 먼저 끝내고 요청한다
- 예외: 사용자가 "직접 실행해봐"라고 하면 그때만 시도한다

## Arguments

`$ARGUMENTS` = 대상 컨텍스트 이름 → 아래 `CTX`에 그대로 넣는다. 인자가 없으면 `kubectl config get-contexts --no-headers -o name` 을 사용자에게 요청해 컨텍스트부터 확정한다. **추측해서 채우지 않는다.**

## 1차 진단 묶음 (기본 출력)

증상이 특정되지 않았을 때 이 한 덩어리를 낸다. `CTX`만 채우면 그대로 붙여넣을 수 있다.

```bash
CTX="<context>"        # ← 여기만 채우고 통째로 붙여넣기
kubectl --context $CTX get nodes -o wide --no-headers
kubectl --context $CTX get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers
kubectl --context $CTX get events -A --sort-by=.lastTimestamp --no-headers | tail -20
kubectl --context $CTX top nodes --no-headers
kubectl --context $CTX get pvc -A --no-headers | grep -v Bound
```

증상이 잡히면 그때 대상별 2차 묶음으로 좁힌다.

## 2차 조회 — 증상별

| 증상 | 명령 |
|------|------|
| Pod 이상 | `describe pod <p> -n <ns>`, `logs <p> -n <ns> --tail=100`, `logs <p> -n <ns> --previous --tail=50` |
| 리소스 압박 | `top pods -A --sort-by=memory --no-headers \| head -15` |
| 네트워크 | `get svc,ingress,endpoints -n <ns> -o wide` |
| PV 사용량 | `get --raw /api/v1/nodes/<node>/proxy/stats/summary \| jq '.pods[].volume[]?'` |
| PV fallback | `describe pv <pv>` → Path 확인 후 node-exporter pod에서 `df -h` (kubelet stats 미지원 시) |
| RPC 노드 | `exec <p> -n <ns> -c <c> -- curl -s -X POST localhost:<port> -d '<jsonrpc>'` |

## 판정 기준

**Pod**: CrashLoopBackOff / Pending / Error / OOMKilled 는 즉시 최상단 보고.

**PVC 사용률**: 70~85% **[WARNING]** · 85~95% **[HIGH]** · 95%+ **[CRITICAL]**
70% 넘으면 `du -sh <path>/*`로 디렉토리별 분석, 연결 워크로드 식별, 파일 타임스탬프로 증가 추세, retention 설정까지 이어서 묻는다.

## Troubleshooting

- **CrashLoop**: Events + `logs --previous` + exit code (137=OOM, 1=app, 139=segfault) + limits
- **Pending**: Events, 노드 가용성, nodeSelector/tolerations/affinity, PVC 바인딩
- **OOMKilled(137)**: `top pod`으로 실사용 확인 후 limits 재검토
- **ImagePullBackOff**: 이미지명/태그, imagePullSecrets
- **Svc 접속불가**: `endpoints` 비어있으면 selector 불일치 → Pod Ready, containerPort=targetPort, NetworkPolicy 순으로
- **PVC 부족**: local-path는 quota가 없다 — 호스트 디스크도 같이 봐야 한다

설계/manifest 작성은 [k8s-craft](../k8s-craft/), 근거 규율이 필요한 장애 분석은 [troubleshoot](../troubleshoot/) 사용.

## Output

어느 컨텍스트 기준인지 먼저 명시. 비정상 항목 최상단 요약. PVC는 테이블(PVC/NS/용량/사용량/사용률/상태). severity 태그. 미확인 항목은 `(미확인)`으로 드러낸다. 조치는 텍스트 안내.
