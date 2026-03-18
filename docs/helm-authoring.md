# Helm Chart Authoring Guide

사용자가 Helm 차트 초기 생성 또는 수정을 요청하면, **파일 작성(Write/Edit)으로만** 대응한다.
인프라에 영향을 주는 helm CLI 명령어(install, upgrade 등)는 절대 실행하지 않는다.

## 차트 스캐폴딩 (신규 차트 생성)

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

## Chart.yaml 베스트 프랙티스

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

## values.yaml 작성 규칙

- 모든 최상위 키에 **주석으로 설명** 추가
- 프로덕션 안전 기본값 사용:
  - `replicaCount: 1` (최소값)
  - `resources.requests`와 `resources.limits` 반드시 포함
  - `securityContext.runAsNonRoot: true`
  - `readinessProbe`와 `livenessProbe` 기본 설정
- Sensitive 값은 values.yaml에 넣지 않고 `existingSecret` 패턴 사용

## Template 작성 규칙

- `_helpers.tpl`에 공통 라벨/셀렉터 정의 (일관성 유지)
- 조건부 리소스는 `{{- if .Values.ingress.enabled }}` 패턴 사용
- `{{ required "message" .Values.key }}` 로 필수값 검증
- `resources`, `securityContext`, `probes` 는 기본 포함
- `{{- toYaml .Values.xxx | nindent N }}` 으로 값 전달

## 기존 차트 수정

- 수정 전 반드시 기존 파일을 Read로 확인
- `helm template`과 `helm lint`로 수정 결과 검증 (이 두 명령은 실행 가능)
- values.yaml 변경 시 기존 배포에 미치는 영향 분석하여 안내

## 환경별 values 분리 패턴

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
