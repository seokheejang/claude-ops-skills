---
name: helm-ops
description: Helm release inspection and chart validation - read-only. Chart mode runs locally; release mode emits copy-paste command bundles for the operator
argument-hint: "<context name | chart path>"
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
---

# Helm Operations Skill

Helm 릴리스 조회 및 차트 검증 전용. **READ-ONLY만.**
금지: `install`, `upgrade`, `uninstall`, `delete`, `rollback`, `repo add/remove/update`, `plugin install`. 필요하면 텍스트로만 안내.

## Arguments

`$ARGUMENTS`가 `/`·`.`로 시작하거나 `Chart.yaml`이 있으면 **차트 모드**(경로), 아니면 **릴리스 모드**(컨텍스트 이름). 인자가 없으면 어느 쪽인지 묻는다.

## 두 모드 — 실행 가능 여부가 다르다

| 모드 | 대상 | 실행 |
|------|------|------|
| **차트 모드** | 로컬 파일 (`lint`, `template`, `show`) | ✅ **직접 실행한다** — 클러스터 접속 불필요 |
| **릴리스 모드** | 클러스터 (`list`, `status`, `get`, `history`) | ❌ 닿지 않는 것을 전제 — 명령 묶음만 출력 |

## 릴리스 모드 — 이 스킬만의 규율

클러스터에 직접 닿지 않는다. 명령을 한 번에 묶어 내는 방식, 화면에 담기게 줄이는 규칙, 붙여넣은 출력을 실측으로 다루는 규칙, `(미확인)` 표기는 **글로벌 CLAUDE.md 「K8s·ArgoCD 등 프록시로 못 보는 것」을 따른다.** Helm에만 해당하는 것은 아래 둘이다.

- **`list`로 먼저 대상을 좁힌 뒤** 릴리스별 조회를 낸다. 릴리스 이름을 모르는 채로 `status`부터 내지 않는다
- **`get manifest`·`get values -a`는 길다** — `| head -n` 없이 내지 않는다

```bash
CTX="<context>"                        # ← 먼저 이 줄만 채우고 list 부터
helm --kube-context $CTX list -A       # 비정상(failed, pending-*) 먼저 식별

REL="<release>"; NS="<namespace>"      # ← list 결과에서 고른 뒤 채우기
helm --kube-context $CTX status  $REL -n $NS
helm --kube-context $CTX history $REL -n $NS
helm --kube-context $CTX get values $REL -n $NS          # 사용자 지정 values만
helm --kube-context $CTX get values $REL -n $NS -a       # 기본값 포함 전체 (길다 — 필요할 때만)
helm --kube-context $CTX get manifest $REL -n $NS | head -60
```

## 차트 모드 — 직접 실행

| 단계 | 명령 | 확인 |
|------|------|------|
| 구조 | `ls <path>/`, Read `Chart.yaml` | apiVersion, name, version 필수 필드 |
| Lint | `helm lint <path>`, `helm lint --strict <path>` | 에러/경고 |
| 렌더링 | `helm template test <path> [-f values.yaml]` | 렌더링 에러, 생성 리소스 목록 |
| 메타데이터 | `helm show chart/values <path>` | dependencies, 기본값 구조 |
| 품질 | Read/Grep | [CRITICAL] 렌더링 에러·deprecated API / [WARNING] limits·probe 미설정 / [INFO] `.helmignore` 누락 |

차트 **작성/수정**은 Write/Edit만 사용. 사내 컨벤션은 claude-ops-skills 저장소의 `docs/helm-authoring.md` 참조 (values 계층화, 환경별 분리 패턴). 표준 Helm 문법은 이미 아는 걸 쓴다.

릴리스가 `failed`·`pending-*` 이면 `history`로 실패 리비전을 짚은 뒤 [k8s-ops](../k8s-ops/)로 실제 리소스 상태를 확인한다.

## Output

어느 컨텍스트/차트 경로 기준인지 먼저 명시. 릴리스는 테이블(Name/NS/Revision/Status/Chart/AppVersion), 비정상 **굵게** 최상단. 차트 검증은 severity별 정리. 미확인은 `(미확인)`. 조치는 텍스트 안내.
