---
name: argocd-ops
description: ArgoCD application inspection, sync status monitoring, and GitOps workflow assistance
argument-hint: "<app-name-or-context>"
allowed-tools: Bash, Read, Grep, Glob
---

# ArgoCD Operations Skill

ArgoCD 애플리케이션 상태 조회, 동기화 모니터링, 드리프트 감지 전용 skill. READ-ONLY 명령어만 실행.

## Safety: READ-ONLY

허용: version, account get-user-info/list, app get/list/logs/manifests/diff/history/resources, repo list/get, cluster list, proj list/get.
금지: app create/delete/sync/rollback/set/patch/terminate-op, repo add/remove, cluster add/remove, proj create/delete/edit, account update-password, login.
변경 필요시 명령어를 텍스트로 안내.

## Connection Resolution

1. `argocd version` → client/server 연결 확인
2. 연결 성공 시 `argocd account get-user-info`로 인증 확인
3. 연결 실패 시: `ARGOCD_SERVER`/`ARGOCD_AUTH_TOKEN` 환경변수, `~/.config/argocd/config` 확인 후 `argocd login <server> --sso` 텍스트 안내

## Arguments

`$ARGUMENTS` 해석: 앱 이름 → 해당 앱 상세 | `project:<name>` → 프로젝트 내 앱 | 없음 → 전체 개요.

## Workflow

| 단계 | 명령어 | 확인 사항 |
|------|--------|-----------|
| 연결 | `argocd version --client`, `account get-user-info` | 인증/연결 상태, 실패시 중단 |
| 전체 개요 | `app list -o wide`, `cluster list`, `proj list` | 비정상 앱 식별 (OutOfSync/Degraded/Missing/Unknown) |
| 앱 상세 | `app get <app> -o wide`, `app resources <app>` | Sync/Health Status, 개별 리소스 health |
| 드리프트 | `app diff <app>` | Config/Image/Resource drift 분류 |
| 배포 이력 | `app history <app>` | 리비전, commit hash, 실패 배포 |
| 로그 | `app logs <app> --tail 100` | Degraded/Missing 앱 에러 패턴 |

## Status Classification

| Sync | Health | Severity | 의미 |
|------|--------|----------|------|
| OutOfSync | Degraded | **[CRITICAL]** | 배포 실패 + 장애 |
| Synced | Degraded | **[CRITICAL]** | 동기화 완료, 장애 |
| OutOfSync/Unknown | Missing/Unknown | **[CRITICAL]** | 리소스 누락/상태 불명 |
| OutOfSync | Healthy | **[WARNING]** | Git 불일치 |
| Synced/OutOfSync | Progressing | **[WARNING]** | 배포 진행 중 (10분+ 주의) |
| Synced | Suspended/Healthy | **[INFO]** | 정상/일시중지 |

## GitOps Manifest Authoring Guide

매니페스트 작성/수정 요청 시 → `Read ${CLAUDE_SKILL_DIR}/../../docs/argocd-authoring.md` 참조. CLI 실행 금지, Write/Edit만 사용.

## Troubleshooting

- **Sync 실패**: `app get` → Conditions, `app diff` → 실패 리소스. 원인: 잘못된 매니페스트, CRD 미존재, RBAC 부족
- **Degraded**: `app resources` → Degraded 리소스 식별, `/k8s-ops`로 연계. 원인: 이미지 풀 실패, 리소스 부족
- **OutOfSync**: `app diff` → 수동 변경 drift vs Git 미sync vs auto-sync 비활성화 구분
- **Repo 연결**: `repo list` → Connection Status. SSH key/token 만료 가능성
- **AppSet 렌더링**: `app list`에서 예상보다 적으면 generator 설정 문제, `/k8s-ops`로 `kubectl get applicationset -A`

## Output

비정상 앱 최상단 요약. Overview Table(App/Project/Cluster/Sync/Health/Source) 사용. severity 태그 적용. 조치는 텍스트 안내.
