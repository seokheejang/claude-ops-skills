# Terraform IaC Authoring Guide

사용자가 Terraform 코드 초기 구축 또는 수정을 요청하면, **파일 작성(Write/Edit)으로만** 대응한다.
인프라에 영향을 주는 terraform CLI 명령어(apply, destroy, init 등)는 절대 실행하지 않는다.

## 프로젝트 스캐폴딩 (신규 프로젝트)

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

## EKS 클러스터 구축 패턴

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

## 모듈 작성 규칙

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

## 보안 베스트 프랙티스 (코드 작성 시)

- 시크릿은 절대 .tf 파일에 하드코딩 금지 → `variable` + `sensitive = true` 또는 AWS Secrets Manager/SSM 참조
- Security Group: 최소 권한 원칙, 0.0.0.0/0 ingress 금지 (필요 시 주석으로 사유 명시)
- IAM: 최소 권한 정책, `"Action": "*"` 금지
- S3: `acl = "private"` 기본, server-side encryption 활성화
- RDS: `publicly_accessible = false`, `storage_encrypted = true`
- 태그 전략: `Name`, `Environment`, `Owner`, `ManagedBy = "terraform"` 기본 포함

## State 관리 패턴

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

## 기존 코드 수정

- 수정 전 반드시 기존 파일을 Read로 확인
- `terraform validate`와 `terraform fmt -check`로 수정 결과 검증 (이 두 명령은 실행 가능)
- 변경 시 `terraform plan` 결과를 분석하여 영향 범위 안내
- apply/init 명령어는 텍스트로만 안내:

```
# (실행하지 않음 - 안내만) terraform init
# (실행하지 않음 - 안내만) terraform plan -out=plan.tfplan
# (실행하지 않음 - 안내만) terraform apply plan.tfplan
```
