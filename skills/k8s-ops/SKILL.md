---
name: k8s-ops
description: Kubernetes read-only inspection - emits copy-paste kubectl command bundles for the operator to run, then interprets the pasted output
argument-hint: "<cluster/context name>"
allowed-tools: Bash, Read, Grep, Glob
---

# K8s Operations Skill

Kubernetes 조회 전용. **READ-ONLY만.** 변경 계열 명령은 settings.json deny 규칙이 차단한다 — 필요하면 텍스트로만 안내.

클러스터에 직접 닿지 않는다. 명령을 한 번에 묶어 내는 방식, 화면에 담기게 줄이는 규칙, 붙여넣은 출력을 실측으로 다루는 규칙, `(미확인)` 표기는 **글로벌 CLAUDE.md 「K8s·ArgoCD 등 프록시로 못 보는 것」을 따른다.** 여기서 다시 적지 않는다.
예외는 하나뿐이다: 사용자가 "직접 실행해봐"라고 하면 그때만 시도한다.

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

> **local-path 는 quota 가 없다** — PVC 용량만 보면 안 되고 호스트 디스크도 같이 봐야 한다. 이 환경 고유 사항이다.

설계/manifest 작성은 [k8s-craft](../k8s-craft/), 근거 규율이 필요한 장애 분석은 [troubleshoot](../troubleshoot/) 사용.

## Output

어느 컨텍스트 기준인지 먼저 명시. 비정상 항목 최상단 요약. PVC는 테이블(PVC/NS/용량/사용량/사용률/상태). severity 태그. 미확인 항목은 `(미확인)`으로 드러낸다. 조치는 텍스트 안내.
