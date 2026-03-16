---
name: terraform-ops
description: Terraform state inspection, plan review, and IaC validation - read-only operations
argument-hint: "<workspace-or-directory>"
allowed-tools: Bash, Read, Grep, Glob
---

# Terraform Operations Skill

Terraform 상태 조회, plan 분석, IaC 검증 전용 skill. READ-ONLY 명령어만 실행.

## CRITICAL SAFETY RULES

**mutating terraform 명령어 절대 실행 금지.**

허용 명령어:
- `terraform version` - 버전 확인
- `terraform state list` - 상태 리소스 목록
- `terraform state show` - 리소스 상세 상태
- `terraform plan` - 변경 계획 미리보기 (인프라 변경 없음, 단 provider API 호출 발생 가능)
- `terraform show` - 현재 상태 또는 plan 파일 조회
- `terraform output` - 출력값 조회
- `terraform providers` - 프로바이더 목록
- `terraform validate` - 구성 파일 문법 검증
- `terraform fmt -check` - 포맷 검사 (수정하지 않음, `-check` 필수)
- `terraform workspace list` - 워크스페이스 목록
- `terraform graph` - 리소스 의존성 그래프
- `terraform console` 사용 금지 (interactive)

**절대 금지**: `apply`, `destroy`, `state rm`, `state mv`, `state push`, `state pull`, `import`, `taint`, `untaint`, `force-unlock`, `workspace new`, `workspace delete`, `workspace select`, `init -upgrade`, `fmt` (without `-check`)
-> 사용자가 요청해도 직접 실행하지 말고 명령어를 텍스트로 안내할 것.

> **참고**: `terraform plan`은 인프라를 변경하지 않지만, provider 인증 및 API 호출이 발생할 수 있다.
> 초기화(`terraform init`)가 되어 있지 않으면 plan이 실행되지 않으며, init이 필요한 경우 텍스트로 안내한다.

## When to Use

- Terraform 상태(state)를 확인할 때
- plan 결과를 분석하고 변경 사항을 검토할 때
- .tf 파일의 문법/포맷을 검증할 때
- 모듈 구조가 베스트 프랙티스를 따르는지 확인할 때
- 상태 파일에서 특정 리소스를 찾을 때
- 보안 관점에서 IaC를 검토할 때

## Arguments

`$ARGUMENTS`를 다음 순서로 해석:

1. 디렉토리 경로인 경우 (예: `./infra`, `/path/to/terraform`) → 해당 디렉토리에서 작업
2. 워크스페이스명인 경우 → 현재 디렉토리에서 해당 워크스페이스 정보 조회
3. 인자 없음 → 현재 디렉토리 사용

판별 기준: 인자가 `/` 또는 `.`으로 시작하거나, 해당 경로에 `.tf` 파일이 존재하면 디렉토리 모드.

## Step-by-Step Workflow

### Step 1: 환경 탐색
```bash
terraform version
terraform workspace list
ls *.tf
```
- Terraform 버전 및 사용 가능한 워크스페이스 확인
- .tf 파일 목록으로 프로젝트 구조 파악
- backend 설정 확인 (Read로 `backend` 블록 탐색)

### Step 2: 구성 검증
```bash
terraform validate
terraform fmt -check -recursive
```
- validate: 구문 에러, 참조 에러, 타입 불일치 등
- fmt -check: 포맷팅 규칙 위반 파일 목록 (수정하지 않음)
- 에러 발생 시 해당 파일:라인 확인 후 원인 분석

### Step 3: 상태 조회
```bash
terraform state list
terraform state show <resource-address>
terraform output
```
- 관리 중인 리소스 총 수 확인
- 사용자가 요청한 특정 리소스 상세 조회
- 출력값 확인 (sensitive 값은 마스킹됨)

### Step 4: Plan 분석
```bash
terraform plan -no-color
```
- 변경 사항을 3가지로 분류:
  - **추가(+)**: 새로 생성될 리소스
  - **변경(~)**: 수정될 리소스 (in-place vs. destroy-and-recreate 구분)
  - **삭제(-)**: 제거될 리소스
- 각 변경의 영향도 분석

**Severity 기준:**
- [CRITICAL] 리소스 삭제(destroy), 특히 stateful 리소스(DB, storage, EBS volume)
- [CRITICAL] destroy-and-recreate (forces replacement) 발생
- [WARNING] Security Group 변경 (특히 ingress 0.0.0.0/0 추가)
- [WARNING] IAM 정책 변경 (권한 확대 방향)
- [WARNING] in-place 변경으로 다운타임 가능성 있는 리소스
- [INFO] 태그 변경, description 변경 등 무해한 수정

> **참고**: `terraform init`이 필요한 경우 plan이 실행되지 않는다. 이 경우 `terraform init` 명령어를 텍스트로 안내하고, .tf 파일을 직접 Read하여 정적 분석을 수행한다.

### Step 5: 보안 검토

.tf 파일을 Grep/Read로 정적 분석:

- [CRITICAL] 하드코딩된 시크릿 (`password`, `secret_key`, `access_key` 등의 값이 리터럴 문자열)
- [CRITICAL] Security Group에 `0.0.0.0/0` ingress (SSH 22, RDP 3389 포트)
- [WARNING] S3 버킷 `acl = "public-read"` 또는 `public-read-write`
- [WARNING] RDS `publicly_accessible = true`
- [WARNING] IAM 정책에 `"Action": "*"` 또는 `"Resource": "*"` (과도한 권한)
- [WARNING] 암호화 미설정 (EBS `encrypted`, RDS `storage_encrypted`, S3 `server_side_encryption_configuration`)
- [INFO] `lifecycle { prevent_destroy }` 미설정인 stateful 리소스
- [INFO] 태그 전략 미적용 (Name, Environment, Owner 등)

### Step 6: 모듈 구조 검토

프로젝트 구조를 Glob/Read로 분석:

- [WARNING] `variables.tf`에 `description` 누락된 변수
- [WARNING] `outputs.tf`에 `description` 누락된 출력
- [WARNING] 버전 제약 없는 provider (`required_providers`에 version 미지정)
- [WARNING] 버전 제약 없는 모듈 (source에 version/ref 미지정)
- [INFO] README.md 미존재 (모듈인 경우)
- [INFO] examples/ 디렉토리 미존재 (모듈인 경우)

## IaC Authoring Guide (파일 작성 모드)

사용자가 Terraform 코드 초기 구축 또는 수정을 요청하면, **파일 작성(Write/Edit)으로만** 대응한다.
인프라에 영향을 주는 terraform CLI 명령어(apply, destroy, init 등)는 절대 실행하지 않는다.

### 프로젝트 스캐폴딩 (신규 프로젝트)

사용자가 새 Terraform 프로젝트를 만들고자 할 때, 다음 구조를 Write 도구로 생성:

```
<project>/
├── main.tf              # 리소스 정의
├── variables.tf         # 입력 변수 (description 필수)
├── outputs.tf           # 출력값 (description 필수)
├── providers.tf         # Provider 설정 + 버전 제약
├── versions.tf          # Terraform 버전 제약 (required_version)
├── backend.tf           # (선택) Remote state backend 설정
├── locals.tf            # (선택) 로컬 변수
├── data.tf              # (선택) Data source
├── terraform.tfvars     # (선택) 변수값 (gitignore 대상)
└── README.md            # (선택) 사용법
```

### EKS 클러스터 구축 패턴

```hcl
# providers.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# main.tf - 검증된 커뮤니티 모듈 사용 권장
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  # ...
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  # ...
}
```

핵심 보안 패턴:
- VPC: Private subnet에 EKS 노드 배치, NAT Gateway 사용
- EKS: Managed Node Groups, IRSA (IAM Roles for Service Accounts)
- 암호화: EBS, Secrets envelope encryption
- 접근: Private endpoint 기본, 필요 시만 Public endpoint

### 모듈 작성 규칙

```
modules/<module-name>/
├── main.tf
├── variables.tf     # 모든 변수에 description + type + validation
├── outputs.tf       # 모든 출력에 description
├── versions.tf      # required_providers
└── README.md        # 사용법, 예시
```

- `description` 은 모든 variable과 output에 필수
- `type` 제약 명시 (string, number, bool, list, map, object)
- `validation` 블록으로 입력값 검증 (가능한 경우)
- `default` 값은 프로덕션 안전 기본값 사용
- `lifecycle { prevent_destroy = true }` 를 stateful 리소스에 적용

### 보안 베스트 프랙티스 (코드 작성 시)

- 시크릿은 절대 .tf 파일에 하드코딩 금지 → `variable` + `sensitive = true` 또는 AWS Secrets Manager/SSM 참조
- Security Group: 최소 권한 원칙, 0.0.0.0/0 ingress 금지 (필요 시 주석으로 사유 명시)
- IAM: 최소 권한 정책, `"Action": "*"` 금지
- S3: `acl = "private"` 기본, server-side encryption 활성화
- RDS: `publicly_accessible = false`, `storage_encrypted = true`
- 태그 전략: `Name`, `Environment`, `Owner`, `ManagedBy = "terraform"` 기본 포함

### State 관리 패턴

```hcl
# backend.tf - S3 + DynamoDB 패턴
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "env/prod/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

- 환경별 state 파일 분리 (dev/staging/prod)
- state 암호화(encrypt = true) 필수
- DynamoDB로 state locking 활성화
- state 파일은 절대 git에 커밋하지 않음 → `.gitignore`에 추가

### 기존 코드 수정

- 수정 전 반드시 기존 파일을 Read로 확인
- `terraform validate`와 `terraform fmt -check`로 수정 결과 검증 (이 두 명령은 실행 가능)
- 변경 시 `terraform plan` 결과를 분석하여 영향 범위 안내
- apply/init 명령어는 텍스트로만 안내:

```
# (실행하지 않음 - 안내만) terraform init
# (실행하지 않음 - 안내만) terraform plan -out=plan.tfplan
# (실행하지 않음 - 안내만) terraform apply plan.tfplan
```

## Troubleshooting Guide

### terraform init 필요
1. `.terraform/` 디렉토리 존재 여부 확인
2. 필요 시 `terraform init` 명령어를 텍스트로 안내
3. backend 설정이 있으면 해당 backend 접근 권한 필요함을 안내

### State lock 에러
1. 에러 메시지에서 Lock ID 확인
2. 누가 lock을 잡고 있는지 확인 (DynamoDB, Consul 등)
3. 해결: `terraform force-unlock <lock-id>` 텍스트 안내 (주의사항 포함)

### Provider 버전 충돌
1. `.terraform.lock.hcl` 파일 확인
2. `required_providers` 블록의 버전 제약 확인
3. 해결: 버전 제약 조정 또는 `terraform init -upgrade` 텍스트 안내

### Plan drift (예상치 못한 변경)
1. `terraform plan`에서 예상치 못한 변경이 나타나는 경우
2. 수동 변경(콘솔/CLI로 직접 변경)으로 인한 drift 가능성
3. `terraform state show <resource>`로 현재 state 확인
4. 실제 인프라와 state 차이 분석

## Output Format

- 어떤 디렉토리/워크스페이스를 대상으로 하는지 먼저 명시
- Terraform 버전 표시
- state 리소스는 테이블로 요약 (리소스 타입별 수량)
- plan 결과는 변경 유형별로 분류 (추가/변경/삭제)
  - 삭제 리소스는 **굵게** 하이라이트하여 최상단에 경고
  - destroy-and-recreate는 **[CRITICAL]** 태그와 함께 강조
- 보안 findings는 severity별 정리: [CRITICAL] -> [WARNING] -> [INFO]
- 조치가 필요한 경우 실행할 명령어를 텍스트로 안내 (직접 실행 금지)
