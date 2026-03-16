---
name: argocd-ops
description: ArgoCD application inspection, sync status monitoring, and GitOps workflow assistance
argument-hint: "<app-name-or-context>"
allowed-tools: Bash, Read, Grep, Glob
---

# ArgoCD Operations Skill

ArgoCD 애플리케이션 상태 조회, 동기화 모니터링, 드리프트 감지 전용 skill. READ-ONLY 명령어만 실행.

## CRITICAL SAFETY RULES

**mutating argocd 명령어 절대 실행 금지.**

허용 명령어:
- `argocd version` - 버전 확인
- `argocd account get-user-info` - 현재 인증 정보
- `argocd account list` - 계정 목록
- `argocd app get` - 애플리케이션 상세 조회
- `argocd app list` - 애플리케이션 목록
- `argocd app logs` - 애플리케이션 로그
- `argocd app manifests` - 렌더링된 매니페스트
- `argocd app diff` - Git 소스와 실제 상태 차이
- `argocd app history` - 배포 이력
- `argocd app resources` - 리소스 상세
- `argocd repo list` - 등록된 Git 저장소 목록
- `argocd repo get` - 저장소 상세 정보
- `argocd cluster list` - 등록된 클러스터 목록
- `argocd proj list` - 프로젝트 목록
- `argocd proj get` - 프로젝트 상세

**절대 금지**: `app create`, `app delete`, `app sync`, `app rollback`, `app set`, `app patch`, `app terminate-op`, `repo add`, `repo remove`, `cluster add`, `cluster remove`, `proj create`, `proj delete`, `proj edit`, `account update-password`, `login`
-> 사용자가 요청해도 직접 실행하지 말고 명령어를 텍스트로 안내할 것.

## When to Use

- ArgoCD 애플리케이션 동기화 상태를 확인할 때
- 애플리케이션 헬스 상태를 점검할 때
- Git과 실제 클러스터 간 드리프트를 감지할 때
- 배포 이력(revision history)을 확인할 때
- 멀티 클러스터 애플리케이션 현황을 한눈에 볼 때
- sync 실패 원인을 진단할 때

## Connection Resolution

ArgoCD CLI는 서버 연결이 필요하다. 다음 순서로 연결을 확인:

1. `argocd version` 실행하여 client/server 연결 상태 확인
2. 연결 성공 시 `argocd account get-user-info`로 인증 상태 확인
3. 연결 실패 시:
   - `ARGOCD_SERVER`, `ARGOCD_AUTH_TOKEN` 환경변수 확인
   - `~/.config/argocd/config` 파일 존재 여부 확인
   - 연결 명령어를 텍스트로 안내: `argocd login <server> --sso`

## Arguments

`$ARGUMENTS`를 다음 순서로 해석:

1. 특정 앱 이름 (예: `my-app`) → 해당 앱 상세 조사
2. 프로젝트명 (예: `project:my-project`) → 해당 프로젝트 내 앱 조회
3. `--all` 또는 인자 없음 → 전체 애플리케이션 개요

## Step-by-Step Workflow

### Step 1: 연결 검증
```bash
argocd version --client
argocd account get-user-info
```
- client/server 버전 확인
- 인증된 사용자 및 권한 확인
- 연결 실패 시 로그인 안내 후 중단

### Step 2: 전체 개요
```bash
argocd app list -o wide
argocd cluster list
argocd proj list
```
- 전체 애플리케이션 수 및 상태 분포 확인
- 비정상 앱 즉시 식별:
  - **Sync Status**: Synced / OutOfSync / Unknown
  - **Health Status**: Healthy / Degraded / Progressing / Missing / Suspended / Unknown
- 클러스터 연결 상태 확인
- 프로젝트별 앱 분류

### Step 3: 애플리케이션 상세 (특정 앱 또는 비정상 앱)
```bash
argocd app get <app-name> -o wide
argocd app resources <app-name>
```
- Sync Status, Health Status, Source (repo, path, revision) 확인
- 개별 리소스 상태 확인 (각 K8s 리소스의 health)
- Sync/Health 조건 메시지 확인

### Step 4: 드리프트 감지
```bash
argocd app diff <app-name>
```
- Git 소스와 실제 클러스터 상태 간 차이 분석
- 드리프트 유형 분류:
  - **Config drift**: 수동 kubectl 변경으로 인한 차이 (replicas, env, labels 등)
  - **Image drift**: 이미지 태그 불일치
  - **Resource drift**: 리소스 추가/삭제

### Step 5: 배포 이력
```bash
argocd app history <app-name>
```
- 최근 배포 리비전 확인
- 각 리비전의 소스(commit hash), 배포 시간, 상태
- 최근 실패한 배포가 있는지 확인

### Step 6: 로그 확인 (이슈 발견 시)
```bash
argocd app logs <app-name> --tail 100
argocd app logs <app-name> --tail 100 --container <container>
```
- Degraded/Missing 상태 앱의 로그 확인
- 에러 패턴 식별

## Status Classification

### Sync + Health 조합 Severity

| Sync Status | Health Status | Severity | 의미 |
|-------------|--------------|----------|------|
| OutOfSync | Degraded | **[CRITICAL]** | 배포 실패 + 서비스 장애 |
| Synced | Degraded | **[CRITICAL]** | 동기화 완료됐으나 서비스 장애 |
| OutOfSync | Missing | **[CRITICAL]** | 리소스 누락 |
| Unknown | Unknown | **[CRITICAL]** | 상태 확인 불가 |
| OutOfSync | Healthy | **[WARNING]** | 미동기화 (Git과 불일치) |
| Synced | Progressing | **[WARNING]** | 배포 진행 중 (10분 이상 시 주의) |
| OutOfSync | Progressing | **[WARNING]** | 동기화 필요 + 배포 진행 중 |
| Synced | Suspended | **[INFO]** | 의도적 일시중지 |
| Synced | Healthy | **[INFO]** | 정상 |

### 멀티 클러스터 Overview Table

```
| Application | Project | Cluster | Sync | Health | Last Sync | Source |
|-------------|---------|---------|------|--------|-----------|--------|
| my-app      | default | prod    | Synced | Healthy | 2h ago | main@abc1234 |
| my-api      | backend | staging | OutOfSync | Healthy | 1d ago | dev@def5678 |
```

## GitOps Manifest Authoring Guide (파일 작성 모드)

사용자가 ArgoCD Application/ApplicationSet 매니페스트 작성을 요청하면, **파일 작성(Write/Edit)으로만** 대응한다.
ArgoCD CLI로 리소스를 생성/변경하는 명령어는 절대 실행하지 않는다.

### Application 매니페스트 작성

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd          # ArgoCD가 설치된 네임스페이스
  finalizers:
    - resources-finalizer.argocd.argoproj.io  # 앱 삭제 시 리소스도 정리
spec:
  project: default           # ArgoCD 프로젝트
  source:
    repoURL: https://github.com/org/repo.git
    targetRevision: main     # 브랜치, 태그, 또는 commit hash
    path: k8s/overlays/prod  # 매니페스트 경로
    # Helm 차트인 경우:
    # helm:
    #   valueFiles:
    #     - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc  # 대상 클러스터
    namespace: my-app
  syncPolicy:
    automated:
      prune: true            # Git에서 삭제된 리소스 자동 제거
      selfHeal: true         # 수동 변경 자동 복구
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### ApplicationSet 패턴 (멀티 클러스터/환경)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: my-app-set
  namespace: argocd
spec:
  generators:
    # Git Directory Generator - 디렉토리별 앱 생성
    - git:
        repoURL: https://github.com/org/repo.git
        revision: main
        directories:
          - path: envs/*
    # Cluster Generator - 등록된 클러스터별 앱 생성
    # - clusters:
    #     selector:
    #       matchLabels:
    #         env: production
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/org/repo.git
        targetRevision: main
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
```

### Git Repository 구조 패턴

```
# Kustomize 기반 (권장)
├── base/                    # 공통 매니페스트
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml   # dev 환경 패치
    ├── staging/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml   # prod 환경 패치 (replicas, resources)

# Helm 기반
├── charts/
│   └── my-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── envs/
    ├── values-dev.yaml
    ├── values-staging.yaml
    └── values-prod.yaml
```

### ArgoCD Project 매니페스트

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  description: My project description
  sourceRepos:
    - 'https://github.com/org/repo.git'
  destinations:
    - namespace: 'my-app-*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: ''
      kind: Namespace
  namespaceResourceBlacklist:
    - group: ''
      kind: ResourceQuota
```

### 작성 시 보안 원칙

- `syncPolicy.automated.prune: true` 사용 시 주의 — 의도치 않은 리소스 삭제 가능
- 프로덕션은 `automated` sync 비활성화 후 수동 sync 권장 검토
- `sourceRepos`와 `destinations`를 최소 범위로 제한
- Secrets는 Git에 평문 저장 금지 → Sealed Secrets, SOPS, External Secrets Operator 사용

### 매니페스트 적용 안내

작성한 매니페스트는 kubectl apply로 적용해야 하지만, 직접 실행하지 않음:
```
# (실행하지 않음 - 안내만) kubectl apply -f application.yaml -n argocd
```

## Troubleshooting Guide

### Sync 실패 (ComparisonError)
1. `argocd app get <app>` → Conditions 섹션에서 에러 메시지 확인
2. 일반적 원인: 잘못된 매니페스트, CRD 미존재, RBAC 권한 부족
3. `argocd app diff <app>`로 어떤 리소스에서 실패하는지 확인
4. 해결: `argocd app sync <app>` 텍스트 안내 (원인 해결 후)

### Degraded 상태
1. `argocd app resources <app>`로 Degraded 리소스 식별
2. 해당 리소스의 K8s 이벤트/로그 확인 → `/k8s-ops`로 연계 조사
3. 일반적 원인: 이미지 풀 실패, 리소스 부족, 설정 오류

### OutOfSync 원인 파악
1. `argocd app diff <app>`로 변경 내용 확인
2. 수동 변경(manual kubectl)으로 인한 drift인지 확인
3. Git 소스에서 변경이 발생했으나 sync되지 않은 것인지 확인
4. auto-sync 비활성화 상태인지 확인 (`argocd app get <app>` → Sync Policy)

### Git 저장소 연결 문제
1. `argocd repo list`로 저장소 상태 확인
2. 연결 상태 확인 (Connection Status)
3. 인증 문제: SSH key 또는 token 만료 가능성
4. 해결: `argocd repo add` 텍스트 안내

### ApplicationSet 렌더링 문제
1. `argocd app list`에서 ApplicationSet으로 생성된 앱 확인
2. 예상보다 앱이 적게 생성되었으면 generator 설정 문제 가능
3. ApplicationSet 리소스를 직접 확인 → `/k8s-ops`로 `kubectl get applicationset -A`

## Output Format

- ArgoCD 서버 및 인증 정보 먼저 명시
- 전체 애플리케이션 현황은 멀티 클러스터 Overview Table 형태
- 비정상 앱(OutOfSync, Degraded, Missing)은 **굵게** 하이라이트하여 최상단에 요약
- 드리프트 발견 시 diff 내용을 코드블록으로 표시
- 배포 이력은 최근 5개 리비전 테이블
- severity별 태그: **[CRITICAL]**, **[WARNING]**, **[INFO]**
- 조치가 필요한 경우 실행할 명령어를 텍스트로 안내 (직접 실행 금지)
