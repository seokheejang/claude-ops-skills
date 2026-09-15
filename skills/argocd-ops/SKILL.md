---
name: argocd-ops
description: ArgoCD application status, sync monitoring, and drift detection - read-only. Emits copy-paste command bundles for the operator, then classifies by severity
argument-hint: "<app-name | project:<name>>"
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
---

# ArgoCD Operations Skill

ArgoCD 앱 상태 조회·동기화 모니터링·드리프트 감지 전용. **READ-ONLY만.**
금지: `app create/delete/sync/rollback/set/patch/terminate-op`, `repo add/rm`, `cluster add/rm`, `proj create/delete/edit/set`, `account update-password`, `login`. 필요하면 텍스트로만 안내.

## 이 스킬만의 규율

ArgoCD 서버에 직접 닿지 않는다. CLI(API)도, 웹 UI도(로그인 월) 마찬가지다. 명령을 한 번에 묶어 내는 방식, 화면에 담기게 줄이는 규칙, 붙여넣은 출력을 실측으로 다루는 규칙, `(미확인)` 표기는 **글로벌 CLAUDE.md 「K8s·ArgoCD 등 프록시로 못 보는 것」을 따른다.** ArgoCD에만 해당하는 것은 하나다.

- **`app list`로 먼저 비정상 앱을 좁힌 뒤** 앱별 조회를 낸다. 앱 이름을 모르는 채로 `app get`부터 내지 않는다

## Arguments

`$ARGUMENTS` 해석: 앱 이름 → 해당 앱 상세 | `project:<name>` → 프로젝트 내 앱 | 없음 → 전체 개요.

## 조회 묶음

```bash
# 전체 개요 — 비정상 앱부터 식별
argocd app list -o wide | grep -Ev 'Synced.*Healthy'

APP="<app>"        # ← 위 결과에서 고른 뒤 채우기

# 앱 상세
argocd app get $APP -o wide
argocd app resources $APP | grep -Ev 'Synced.*Healthy'

# 드리프트 / 이력 / 로그
argocd app diff $APP
argocd app history $APP | tail -10
argocd app logs $APP --tail 100

# 연결 문제 의심 시
argocd version --client && argocd account get-user-info
argocd repo list
```

연결 실패하면 `ARGOCD_SERVER`/`ARGOCD_AUTH_TOKEN` 환경변수와 `~/.config/argocd/config`를 확인하게 하고 `argocd login <server> --sso`를 텍스트로 안내한다.

## Severity 분류

| Sync | Health | Severity | 의미 |
|------|--------|----------|------|
| OutOfSync | Degraded | **[CRITICAL]** | 배포 실패 + 장애 |
| Synced | Degraded | **[CRITICAL]** | 동기화 완료, 장애 |
| OutOfSync/Unknown | Missing/Unknown | **[CRITICAL]** | 리소스 누락/상태 불명 |
| OutOfSync | Healthy | **[WARNING]** | Git 불일치 |
| Synced/OutOfSync | Progressing | **[WARNING]** | 배포 진행 중 (10분+ 주의) |
| Synced | Suspended/Healthy | **[INFO]** | 정상/일시중지 |

## 다른 스킬로 넘기는 지점

- 리소스가 **Degraded** 면 `app resources`로 대상을 짚은 뒤 [k8s-ops](../k8s-ops/)로 Pod 레벨을 확인한다
- `app list` 결과가 예상보다 적으면 ApplicationSet 렌더링 문제다 → [k8s-ops](../k8s-ops/)로 `kubectl --context $CTX get applicationset -A`

## 매니페스트 작성

Application/ApplicationSet/AppProject 작성은 Write/Edit만 사용, CLI 실행 금지. 사내 컨벤션(Git repo 구조, 보안 원칙)은 claude-ops-skills 저장소의 `docs/argocd-authoring.md` 참조. 표준 CRD 스펙은 이미 아는 걸 쓴다.

## Output

비정상 앱 최상단 요약. Overview 테이블(App/Project/Cluster/Sync/Health/Source). severity 태그. 미확인은 `(미확인)`. 조치는 텍스트 안내.
