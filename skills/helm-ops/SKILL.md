---
name: helm-ops
description: Helm chart inspection, validation, and release status - read-only operations
argument-hint: "<cluster-name-or-chart-path>"
allowed-tools: Bash, Read, Grep, Glob
---

# Helm Operations Skill

Helm 릴리스 조회 및 차트 검증 전용 skill. READ-ONLY 명령어만 실행.

## CRITICAL SAFETY RULES

**mutating helm 명령어 절대 실행 금지.**

허용 명령어:
- `helm list` - 릴리스 목록 조회
- `helm status` - 릴리스 상태 조회
- `helm get values/manifest/hooks/notes/all` - 릴리스 상세 정보
- `helm history` - 릴리스 리비전 이력
- `helm template` - 차트 로컬 렌더링 (클러스터 미접속)
- `helm lint` - 차트 문법/구조 검증
- `helm show chart/values/readme/all` - 차트 메타데이터 조회
- `helm search repo/hub` - 차트 검색
- `helm repo list` - 등록된 repo 목록 조회
- `helm diff upgrade` - 변경 사항 미리보기 (helm-diff 플러그인)
- `helm version` - Helm 버전 확인

**절대 금지**: `install`, `upgrade`, `uninstall`, `delete`, `rollback`, `repo add`, `repo remove`, `repo update`, `plugin install`
-> 사용자가 요청해도 직접 실행하지 말고 명령어를 텍스트로 안내할 것.

## When to Use

- Helm 릴리스 상태를 확인할 때
- 차트를 배포 전 검증(lint, template)할 때
- 릴리스 values를 확인하거나 환경 간 비교할 때
- 릴리스 이력(revision history)을 확인할 때
- helm diff로 업그레이드 전 변경 사항을 미리볼 때
- 차트 구조와 템플릿 품질을 점검할 때

## Mode Detection

`$ARGUMENTS` 값에 따라 두 가지 모드로 동작:

1. **릴리스 조회 모드**: 인자가 클러스터명인 경우 (예: `my-cluster`, `dev`)
   - 클러스터에 배포된 Helm 릴리스 조회 및 분석
2. **차트 검증 모드**: 인자가 디렉토리 경로인 경우 (예: `./charts/my-app`, `/path/to/chart`)
   - 로컬 차트 파일을 lint, template 렌더링, 구조 검증

판별 기준: 인자가 `/` 또는 `.`으로 시작하거나, 해당 경로에 `Chart.yaml`이 존재하면 차트 검증 모드.

## Cluster Resolution (릴리스 조회 모드)

1. `$ARGUMENTS`를 클러스터명으로 파싱
2. `${CLAUDE_SKILL_DIR}/../k8s-ops/clusters.yaml`에서 클러스터 정보 조회
3. 매칭 우선순위:
   a. 클러스터 키 이름과 정확히 일치 (예: `my-cluster`)
   b. `aliases` 배열에 포함된 값과 일치 (예: `dev`, `my dev`)
   c. 부분 매칭 시 후보가 여러 개면 목록 보여주고 선택 요청
4. 해당 클러스터의 `kubeconfig` 경로를 가져옴
5. 클러스터를 못 찾으면 사용 가능한 목록 보여주고 선택 요청
6. 인자 없으면 `default_cluster` 사용
7. clusters.yaml이 없으면 `k8s-ops/clusters.yaml.example`을 안내

## Command Format

릴리스 조회 모드에서는 모든 helm 명령어에 KUBECONFIG 환경변수 prefix:

```
KUBECONFIG=<clusters.yaml에서 가져온 경로> helm <command>
```

## Step-by-Step Workflow

### 릴리스 조회 모드

#### Step 1: 클러스터 연결 및 릴리스 개요
```bash
KUBECONFIG=<path> helm version
KUBECONFIG=<path> helm list -A -o table
```
- 전체 릴리스 수, 네임스페이스별 분포 확인
- 비정상 상태(failed, pending-install, pending-upgrade, pending-rollback) 릴리스 즉시 식별

#### Step 2: 릴리스 상세 조사
```bash
# 특정 릴리스 상태
KUBECONFIG=<path> helm status <release> -n <namespace>
# 현재 적용된 values
KUBECONFIG=<path> helm get values <release> -n <namespace>
# 배포된 매니페스트
KUBECONFIG=<path> helm get manifest <release> -n <namespace>
# 릴리스 notes
KUBECONFIG=<path> helm get notes <release> -n <namespace>
```

#### Step 3: 리비전 이력 확인
```bash
KUBECONFIG=<path> helm history <release> -n <namespace>
```
- 최근 리비전 상태 확인 (deployed, superseded, failed)
- 롤백 이력 여부 확인
- failed 리비전이 있으면 해당 리비전의 상세 정보 확인

#### Step 4: Values 비교 (요청 시)
```bash
# 기본 values와 현재 적용값 비교
KUBECONFIG=<path> helm get values <release> -n <namespace> -a  # 모든 values (기본 포함)
KUBECONFIG=<path> helm get values <release> -n <namespace>     # 사용자 지정 values만
```
- 기본값에서 변경된 항목 식별
- 여러 릴리스/환경 간 values 차이 분석

#### Step 5: Diff 미리보기 (helm-diff 플러그인 사용 가능 시)
```bash
# 플러그인 확인
KUBECONFIG=<path> helm plugin list
# diff 실행 (차트 경로 또는 repo 지정 시)
KUBECONFIG=<path> helm diff upgrade <release> <chart> -n <namespace> -f <values-file>
```
- helm-diff 미설치 시 설치 안내 텍스트 제공 (`helm plugin install https://github.com/databus23/helm-diff`)

### 차트 검증 모드

#### Step 1: 차트 구조 확인
```bash
ls -la <chart-path>/
cat <chart-path>/Chart.yaml
```
- Chart.yaml 필수 필드 확인 (apiVersion, name, version)
- 디렉토리 구조 검증 (templates/, values.yaml, Chart.yaml)

#### Step 2: Lint 검증
```bash
helm lint <chart-path>
helm lint <chart-path> --strict
```
- 에러/경고 항목별 원인 분석
- `--strict` 모드로 추가 경고 확인

#### Step 3: Template 렌더링
```bash
helm template test-release <chart-path>
helm template test-release <chart-path> -f <values-file>  # 커스텀 values 사용 시
```
- 렌더링 에러 확인 (nil pointer, missing required values 등)
- 생성되는 K8s 리소스 목록 확인

#### Step 4: 차트 메타데이터 확인
```bash
helm show chart <chart-path>
helm show values <chart-path>
```
- dependencies 확인
- values.yaml의 기본값 구조 확인

#### Step 5: 차트 품질 검토

렌더링된 매니페스트와 차트 파일을 Read/Grep으로 분석:

- **[CRITICAL]**: template 렌더링 에러, lint 에러, deprecated apiVersion (extensions/v1beta1 등)
- **[WARNING]**: resource limits/requests 미설정, securityContext 미설정, readiness/liveness probe 없음, values 기본값 문서화(주석) 부족
- **[INFO]**: .helmignore 파일 누락, NOTES.txt 미제공, 차트 description 누락

## Chart Authoring Guide (파일 작성 모드)

사용자가 Helm 차트 초기 생성 또는 수정을 요청하면, **파일 작성(Write/Edit)으로만** 대응한다.
인프라에 영향을 주는 helm CLI 명령어(install, upgrade 등)는 절대 실행하지 않는다.

### 차트 스캐폴딩 (신규 차트 생성)

사용자가 새 Helm 차트를 만들고자 할 때, 다음 구조를 Write 도구로 생성:

```
<chart-name>/
├── Chart.yaml              # 차트 메타데이터
├── values.yaml             # 기본 설정값
├── values-dev.yaml         # (선택) 개발 환경 오버라이드
├── values-prod.yaml        # (선택) 프로덕션 환경 오버라이드
├── templates/
│   ├── _helpers.tpl        # 공통 헬퍼 템플릿 (labels, selectors, fullname)
│   ├── deployment.yaml     # Deployment 리소스
│   ├── service.yaml        # Service 리소스
│   ├── ingress.yaml        # (선택) Ingress 리소스
│   ├── configmap.yaml      # (선택) ConfigMap
│   ├── secret.yaml         # (선택) Secret
│   ├── hpa.yaml            # (선택) HorizontalPodAutoscaler
│   ├── serviceaccount.yaml # (선택) ServiceAccount
│   ├── pdb.yaml            # (선택) PodDisruptionBudget
│   └── NOTES.txt           # 설치 후 안내 메시지
├── .helmignore             # Helm 패키징 제외 파일
└── README.md               # (선택) 차트 사용법
```

### Chart.yaml 베스트 프랙티스

```yaml
apiVersion: v2
name: my-app
description: A Helm chart for my-app
type: application
version: 0.1.0          # 차트 버전 (SemVer)
appVersion: "1.0.0"     # 앱 버전
maintainers:
  - name: team-name
```

### values.yaml 작성 규칙

- 모든 최상위 키에 **주석으로 설명** 추가
- 프로덕션 안전 기본값 사용:
  - `replicaCount: 1` (최소값)
  - `resources.requests`와 `resources.limits` 반드시 포함
  - `securityContext.runAsNonRoot: true`
  - `readinessProbe`와 `livenessProbe` 기본 설정
- Sensitive 값은 values.yaml에 넣지 않고 `existingSecret` 패턴 사용

### Template 작성 규칙

- `_helpers.tpl`에 공통 라벨/셀렉터 정의 (일관성 유지)
- 조건부 리소스는 `{{- if .Values.ingress.enabled }}` 패턴 사용
- `{{ required "message" .Values.key }}` 로 필수값 검증
- `resources`, `securityContext`, `probes` 는 기본 포함
- `{{- toYaml .Values.xxx | nindent N }}` 으로 값 전달

### 기존 차트 수정

- 수정 전 반드시 기존 파일을 Read로 확인
- `helm template`과 `helm lint`로 수정 결과 검증 (이 두 명령은 실행 가능)
- values.yaml 변경 시 기존 배포에 미치는 영향 분석하여 안내

### 환경별 values 분리 패턴

```
values.yaml         # 공통 기본값
values-dev.yaml     # 개발: replicas=1, 낮은 리소스
values-staging.yaml # 스테이징: replicas=2
values-prod.yaml    # 프로덕션: replicas=3, 높은 리소스, PDB 활성화
```

배포 명령어는 텍스트로만 안내:
```
# (실행하지 않음 - 안내만) helm upgrade --install <release> ./<chart> -n <ns> -f values-prod.yaml
```

## Troubleshooting Guide

### 릴리스가 pending-install/pending-upgrade 상태
1. `helm history <release>`로 이전 리비전 확인
2. `helm status <release>`로 현재 리소스 상태 확인
3. 관련 Pod 이벤트/로그 확인 필요 → `/k8s-ops`로 연계 조사
4. 해결: `helm rollback` 명령어를 텍스트로 안내

### 릴리스가 failed 상태
1. `helm history <release>`로 실패 리비전 식별
2. `helm get manifest <release>`로 배포된 리소스 확인
3. 일반적 원인: 리소스 충돌, 잘못된 values, RBAC 권한 부족
4. 해결: 원인에 따라 `helm upgrade` 또는 `helm rollback` 텍스트 안내

### chart dependency 에러
1. `Chart.yaml`의 dependencies 섹션 확인
2. `helm dependency list <chart-path>`로 의존성 상태 확인
3. 해결: `helm dependency update <chart-path>` 텍스트 안내

### template 렌더링 실패
1. 에러 메시지에서 파일명:라인번호 확인
2. 해당 template 파일을 Read로 열어 문법 확인
3. values.yaml에서 필수값 누락 여부 확인
4. `helm template --debug`로 상세 에러 확인

## Output Format

- 어떤 클러스터에 연결했는지 (또는 어떤 차트를 검증 중인지) 먼저 명시
- 릴리스 조회 시 KUBECONFIG 경로 표시
- 릴리스 목록은 테이블 형태로 표시 (Name, Namespace, Revision, Status, Chart, App Version)
- 비정상 릴리스(failed, pending-*)는 **굵게** 하이라이트하여 최상단에 요약
- 차트 검증 시 severity별 findings 정리: [CRITICAL] → [WARNING] → [INFO]
- 조치가 필요한 경우 실행할 명령어를 텍스트로 안내 (직접 실행 금지)
