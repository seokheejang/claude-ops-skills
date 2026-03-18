---
name: terraform-ops
description: Terraform state inspection, plan review, and IaC validation - read-only operations
argument-hint: "<workspace-or-directory>"
allowed-tools: Bash, Read, Grep, Glob
---

# Terraform Operations Skill

Terraform 상태 조회, plan 분석, IaC 검증 전용 skill. READ-ONLY 명령어만 실행.

## Safety: READ-ONLY

허용: version, state list/show, plan, show, output, providers, validate, `fmt -check`, workspace list, graph.
금지: apply, destroy, state rm/mv/push/pull, import, taint, untaint, force-unlock, workspace new/delete/select, `init -upgrade`, `fmt` (without -check), console.
변경 필요시 명령어를 텍스트로 안내.

> `terraform plan`은 인프라 변경 없으나 provider API 호출 발생 가능. init 미완료시 plan 실행 불가 → init 텍스트 안내 후 .tf 정적 분석 수행.

## Arguments

`$ARGUMENTS` 해석: `/` 또는 `.` 시작 또는 `.tf` 존재 → 디렉토리 모드 | 워크스페이스명 → 해당 워크스페이스 | 없음 → 현재 디렉토리.

## Workflow

| 단계 | 명령어 | 확인 사항 |
|------|--------|-----------|
| 환경 탐색 | `version`, `workspace list`, `ls *.tf` | 버전, 워크스페이스, backend 설정 (Read) |
| 구성 검증 | `validate`, `fmt -check -recursive` | 구문 에러, 포맷 위반 파일 |
| 상태 조회 | `state list`, `state show <addr>`, `output` | 관리 리소스 수, 특정 리소스 상세, 출력값 |
| Plan 분석 | `plan -no-color` | 추가(+)/변경(~)/삭제(-) 분류, destroy-and-recreate 주의 |
| 보안 검토 | Grep/Read 정적 분석 | 하드코딩 시크릿, 0.0.0.0/0 SG, public S3/RDS, IAM * |
| 모듈 검토 | Glob/Read 분석 | description 누락, provider/module 버전 미지정, README 미존재 |

### Plan Severity 기준

- **[CRITICAL]**: 리소스 삭제(특히 stateful), destroy-and-recreate(forces replacement)
- **[WARNING]**: SG 변경(0.0.0.0/0), IAM 권한 확대, 다운타임 가능 in-place 변경
- **[INFO]**: 태그/description 변경

### 보안 검토 항목

- [CRITICAL] 하드코딩 시크릿 (password, secret_key, access_key 리터럴)
- [CRITICAL] SG `0.0.0.0/0` ingress (SSH 22, RDP 3389)
- [WARNING] S3 `public-read`, RDS `publicly_accessible=true`, IAM `"Action":"*"`, 암호화 미설정
- [INFO] `prevent_destroy` 미설정 stateful 리소스, 태그 전략 미적용

## IaC Authoring Guide

IaC 작성/수정 요청 시 → `Read ${CLAUDE_SKILL_DIR}/../../docs/terraform-authoring.md` 참조. CLI 실행 금지, Write/Edit만 사용.

## Troubleshooting

- **init 필요**: `.terraform/` 존재 확인, `terraform init` 텍스트 안내, backend 접근 권한 필요
- **State lock**: 에러의 Lock ID 확인, `force-unlock <id>` 텍스트 안내 (주의사항 포함)
- **Provider 버전 충돌**: `.terraform.lock.hcl` + `required_providers` 확인, `init -upgrade` 텍스트 안내
- **Plan drift**: `state show <resource>`로 현재 state 확인, 수동 변경(콘솔/CLI) drift 분석

## Output

디렉토리/워크스페이스 먼저 명시. state는 리소스 타입별 수량 테이블. plan은 변경 유형별 분류, 삭제 **굵게** 최상단 경고. 보안 findings는 severity별 정리. 조치는 텍스트 안내.
