---
name: argocd-ops
description: ArgoCD application status, sync monitoring, and drift detection - read-only. Emits copy-paste command bundles for the operator, then classifies by severity
argument-hint: "<app-name | project:<name>>"
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
---

# ArgoCD Operations Skill

ArgoCD 앱 상태 조회·동기화 모니터링·드리프트 감지 전용. **READ-ONLY만.**
금지: `app create/delete/sync/rollback/set/patch/terminate-op`, `repo add/remove`, `cluster add/remove`, `proj create/delete/edit`, `account update-password`, `login`. 필요하면 텍스트로만 안내.

## 실행 모델 — 명령은 내가, 실행은 사용자가

**ArgoCD 서버에 직접 닿지 않는 것을 전제한다** — CLI(API)도, 웹 UI도(로그인 월). 시도해서 실패한 뒤 알아차리지 말고 처음부터 그렇게 움직인다.

- `app list`로 먼저 비정상 앱을 좁힌 뒤 앱별 조회를 낸다. 앱 이름을 모르는 채로 `app get`부터 내지 않는다
- 결과가 **스크린샷으로 돌아오므로 화면에 담기게** 줄인다 — `grep -Ev 'Synced.*Healthy'`로 정상 앱을 걸러내고, `diff`·`logs`는 `| head -n` / `--tail`로 자른다
- 돌아온 출력은 **실측**으로 다룬다. 단 어느 ArgoCD 인스턴스/클러스터 것인지 불분명하면 그것부터 되묻는다
- 확인 못 한 것은 `(미확인)`으로 남긴다. **추측으로 메우지 않는다**
- 예외: 사용자가 "직접 실행해봐"라고 하면 그때만 시도한다

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

## Troubleshooting

- **Sync 실패**: `app get` → Conditions, `app diff` → 실패 리소스. 원인은 잘못된 매니페스트 / CRD 미존재 / RBAC 부족
- **Degraded**: `app resources`로 Degraded 리소스 식별 → [k8s-ops](../k8s-ops/) 연계. 원인은 이미지 풀 실패 / 리소스 부족
- **OutOfSync**: `app diff`로 수동 변경 drift vs Git 미sync vs auto-sync 비활성화를 구분
- **Repo 연결**: `repo list` → Connection Status. SSH key/token 만료 가능성
- **AppSet 렌더링**: `app list`가 예상보다 적으면 generator 설정 문제 → [k8s-ops](../k8s-ops/)로 `kubectl --context $CTX get applicationset -A`

## 매니페스트 작성

Application/ApplicationSet/AppProject 작성은 Write/Edit만 사용, CLI 실행 금지. 사내 컨벤션(Git repo 구조, 보안 원칙)은 claude-ops-skills 저장소의 `docs/argocd-authoring.md` 참조. 표준 CRD 스펙은 이미 아는 걸 쓴다.

## Output

비정상 앱 최상단 요약. Overview 테이블(App/Project/Cluster/Sync/Health/Source). severity 태그. 미확인은 `(미확인)`. 조치는 텍스트 안내.
