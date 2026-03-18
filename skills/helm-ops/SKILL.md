---
name: helm-ops
description: Helm chart inspection, validation, and release status - read-only operations
argument-hint: "<cluster-name-or-chart-path>"
allowed-tools: Bash, Read, Grep, Glob
---

# Helm Operations Skill

Helm 릴리스 조회 및 차트 검증 전용 skill. READ-ONLY 명령어만 실행.

## Safety: READ-ONLY

허용: list, status, get values/manifest/hooks/notes/all, history, template, lint, show chart/values/readme/all, search repo/hub, repo list, diff upgrade, version.
금지: install, upgrade, uninstall, delete, rollback, repo add/remove/update, plugin install.
변경 필요시 명령어를 텍스트로 안내.

## Mode Detection

`$ARGUMENTS` 판별: `/` 또는 `.`으로 시작하거나 `Chart.yaml` 존재 → **차트 검증 모드**. 그 외 → **릴리스 조회 모드**.

## Cluster Resolution (릴리스 조회 모드)

`$ARGUMENTS` → `${CLAUDE_SKILL_DIR}/../k8s-ops/clusters.yaml`에서 매칭 (정확→alias→부분). 미매칭시 목록 표시. 인자 없으면 default_cluster. 모든 명령어에 `KUBECONFIG=<path>` prefix.

## Workflow: 릴리스 조회

| 단계 | 명령어 | 확인 사항 |
|------|--------|-----------|
| 연결/개요 | `helm version`, `helm list -A -o table` | 비정상 릴리스 (failed, pending-*) 즉시 식별 |
| 릴리스 상세 | `helm status <rel> -n <ns>`, `get values`, `get manifest`, `get notes` | 상태, 적용 values, 배포 매니페스트 |
| 이력 | `helm history <rel> -n <ns>` | deployed/failed/superseded, 롤백 이력 |
| Values 비교 | `get values -a` (전체) vs `get values` (사용자 지정) | 기본값 변경 항목, 환경간 차이 |
| Diff | `helm plugin list`, `helm diff upgrade <rel> <chart>` | 업그레이드 전 변경 미리보기 |

## Workflow: 차트 검증

| 단계 | 명령어 | 확인 사항 |
|------|--------|-----------|
| 구조 | `ls <path>/`, `cat Chart.yaml` | apiVersion, name, version 필수 필드 |
| Lint | `helm lint <path>`, `helm lint --strict` | 에러/경고 분석 |
| Template | `helm template test-release <path> [-f values]` | 렌더링 에러, 생성 리소스 목록 |
| 메타데이터 | `helm show chart/values <path>` | dependencies, 기본값 구조 |
| 품질 | Read/Grep 분석 | [CRITICAL] 렌더링 에러, deprecated API / [WARNING] limits/probes 미설정 / [INFO] .helmignore 누락 |

## Chart Authoring Guide

차트 작성/수정 요청 시 → `Read ${CLAUDE_SKILL_DIR}/../../docs/helm-authoring.md` 참조. CLI 실행 금지, Write/Edit만 사용.

## Troubleshooting

- **pending-install/upgrade**: `history` → 이전 리비전, `status` → 리소스 상태, `/k8s-ops` 연계. 해결: `helm rollback` 텍스트 안내
- **failed**: `history` → 실패 리비전, `get manifest` → 배포 리소스. 원인: 리소스 충돌, 잘못된 values, RBAC 부족
- **dependency 에러**: `Chart.yaml` dependencies 확인, `helm dependency list`. 해결: `helm dependency update` 텍스트 안내
- **template 렌더링 실패**: 에러 메시지 파일:라인 확인, values 필수값 누락, `helm template --debug`

## Output

클러스터/차트 대상 먼저 명시. 릴리스는 테이블(Name/NS/Revision/Status/Chart/AppVersion). 비정상 **굵게** 최상단. 차트 검증은 severity별 정리. 조치는 텍스트 안내.
