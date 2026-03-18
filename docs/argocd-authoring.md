# GitOps Manifest Authoring Guide

사용자가 ArgoCD Application/ApplicationSet 매니페스트 작성을 요청하면, **파일 작성(Write/Edit)으로만** 대응한다.
ArgoCD CLI로 리소스를 생성/변경하는 명령어는 절대 실행하지 않는다.

## Application 매니페스트 작성

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

## ApplicationSet 패턴 (멀티 클러스터/환경)

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

## Git Repository 구조 패턴

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

## ArgoCD Project 매니페스트

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

## 작성 시 보안 원칙

- `syncPolicy.automated.prune: true` 사용 시 주의 — 의도치 않은 리소스 삭제 가능
- 프로덕션은 `automated` sync 비활성화 후 수동 sync 권장 검토
- `sourceRepos`와 `destinations`를 최소 범위로 제한
- Secrets는 Git에 평문 저장 금지 → Sealed Secrets, SOPS, External Secrets Operator 사용

## 매니페스트 적용 안내

작성한 매니페스트는 kubectl apply로 적용해야 하지만, 직접 실행하지 않음:
```
# (실행하지 않음 - 안내만) kubectl apply -f application.yaml -n argocd
```
