---
name: k8s-craft
description: Author and design Kubernetes manifests — workloads, networking, storage, RBAC, NetworkPolicy, cost, operators, mesh, multi-cluster. Use when the user wants to create, design, write, scaffold, or review YAML manifests, asks "manifest 만들어줘", "K8s 설계", "deployment YAML", "RBAC 작성". Paired with k8s-ops (inspection).
argument-hint: "<resource type or design topic>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# k8s-craft

K8s 리소스 작성/설계 스킬. **manifest 파일 출력 + 적용 명령어 텍스트 안내만** 한다.
조회/디버깅은 [k8s-ops](../k8s-ops/) 사용.

표준 리소스 스펙(apiVersion, 필드, Istio/CRD 문법 등)은 네가 이미 아는 걸 쓴다. 이 파일은 **우리 환경의 결정사항과 가드레일**만 고정한다.

## Safety Rules

**kubectl 변경 명령어 직접 실행 절대 금지** — 글로벌 CLAUDE.md 규칙.

| 동작 | 허용 |
|------|------|
| YAML manifest 파일 출력 (Write/Edit) | ✅ |
| `kubectl explain`, `kubeval`, `kustomize build`, `helm template` | ✅ |
| `kubectl apply --dry-run=client` (로컬 스키마 검증, 클러스터 접속 없음) | ✅ |
| `kubectl apply --dry-run=server` | ⚠️ 클러스터 접속 필요 — 명령어만 안내 |
| `apply / create / replace / patch / edit / scale / delete / rollout / cordon / drain` | ❌ |

## Workflow

1. **요구사항 파악** — 워크로드 종류, 스케일링, 보안 요구사항, 의존성. 애매하면 묻는다
2. **manifest 작성** — `docs/k8s/<name>.yaml` 또는 사용자 지정 경로
3. **로컬 검증** — `kubectl apply --dry-run=client -f <file>` 또는 `kubeval`
4. **적용 안내** — 명령어를 복붙 가능한 블록으로 제공. 실행은 사용자

## 우리 환경의 결정사항

표준 모범사례(resource limits, probe, Secret 분리, 최소 권한 RBAC, `latest` 태그 회피 등)는 적지 않는다 — 지시 없이도 적용되는 것이고, 적어두면 낡아서 틀린 답의 근거가 된다. 여기 남기는 것은 우리가 따로 정한 것뿐이다.

- **NetworkPolicy 를 기본으로 넣는다** — 네임스페이스 격리만으로 끝내지 않는다
- **ClusterRole 을 쓸 때는 왜 Role 로 안 되는지 근거를 주석에 남긴다**
- 버전 종속적 선택(apiVersion, 특정 애드온)은 **어느 버전 기준인지 명시**한다

## Output

- 파일 경로: 사용자 지정 또는 `docs/k8s/<resource>-<name>.yaml`
- 멀티 리소스는 `---` 구분자
- 적용 명령어는 복붙 블록으로 (실행 X)
- 설계 결정 근거 1~2줄 요약

원본: github.com/Jeffallan/claude-skills (MIT) — 우리 컨벤션에 맞게 customize.
