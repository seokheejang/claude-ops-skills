# write-a-skill — Reference

SKILL.md 본문에서 분리한 상세 가이드.

## 추론 자유도 — 작성 패턴

SKILL.md "추론 자유도" 섹션에서 **이탈 비용**으로 정한 성격을 실제 본문으로 옮기는 법. 핵심 전제: 스킬은 모델 추론을 대체하는 엔진이 아니라 가드레일이고, 모델 업데이트로 좋아지는 "어떻게"는 위임형에서 자동 흡수된다.

### 가드레일형 (추론 위임) 작성법

읽기 전용·열린 분석처럼 모델 즉흥이 틀려도 blast radius가 작은 스킬.

- **목표 먼저** — 이 스킬이 끝났을 때 무엇이 나와야 하는지 한 문장으로
- **출처·수단은 floor로** — "최소한 이건 봐라, 바닥선이지 상한선이 아니다. 더 정확·최신 방법을 알면 그걸 우선하라"는 **위임 문구를 명시**. 이 문구가 없으면 모델은 적힌 절차를 상한선으로 읽고 거기서 멈춘다
- **불변 조건만 고정** — 읽기 전용, 사실/추측 분리, 자동 시작 금지 등 모델이 좋아져도 자동 보장되지 않는 규율
- 출력 형식은 일관성이 필요하면 고정, 아니면 풀어둔다

예: `catchup` — 목표(3-파트 브리핑 고정) + 출처 floor(git/문서/메모리) + 불변 조건(읽기 전용·사실/추측 분리)

### 절차 고정형 작성법

K8s/서버/DB 운용 등 즉흥이 write·사고·비용으로 이어지는 스킬.

- **허용/금지 명령 명시 열거** (Safety Rules). "변경 명령은 텍스트로만 안내" 같은 hard 제약
- **순서·도구를 고정**, 모델 판단에 맡기지 않는다
- 결정론이 필요하면 SKILL.md 본문이 아니라 `scripts/`로 빼서 매번 같은 코드가 돌게 한다
- "더 나은 방법을 우선하라" 같은 위임 문구는 **넣지 않는다**

예: `k8s-ops` — READ-ONLY 화이트리스트 + 고정 Operations 표

### 혼합 (대부분의 스킬)

안전 규율·출력 계약은 고정 + 그 안의 분석·탐색은 위임. `ralph`는 "고정 루프 N회" 구조는 고정이지만 각 라운드의 검토 내용은 모델에 위임한다.

## Structure Patterns

스킬 디렉토리 구조는 **필요할 때만 점진적으로 확장**한다. 기본은 SKILL.md 단일 파일.

### 분리 트리거

| 상황 | 추가할 것 | 비고 |
|------|----------|------|
| SKILL.md가 100줄 넘음, 분리 토픽 1~2개 | `REFERENCE.md` | mmdraw 패턴 |
| 독립 토픽이 3개 이상, 도메인이 깊음 | `references/<topic>.md` | kubernetes-specialist 패턴 |
| 매번 같은 코드를 LLM이 재생성하게 됨 | `scripts/*.sh|py` | rpc-agent, mmdraw 패턴 |
| YAML/JSON 템플릿, 샘플, 정적 자원 필요 | `assets/*` | manifest 템플릿 등 |

### `references/` 사용 시 SKILL.md에 가이드 표 두기

3개 이상의 reference 파일이 있으면, SKILL.md 본문에 어떤 상황에 어떤 파일을 로드할지 명시한 표를 둔다. 모델이 컨텍스트를 절약하면서 정확히 필요한 자료만 로드할 수 있도록.

예시:
```md
## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Networking | `references/networking.md` | Services, Ingress, NetworkPolicy 작업 |
| Storage | `references/storage.md` | PV, PVC, StorageClass 작업 |
| Troubleshooting | `references/troubleshooting.md` | 에러 분석, 디버깅 |
```

### When to Add Scripts

다음 중 하나라도 해당되면 `scripts/`로 분리:
- 결정론적 작업 (검증, 포맷팅, 파싱, 렌더링)
- 매번 같은 코드를 LLM이 재생성할 가능성
- 명시적 에러 핸들링 필요
- fallback 로직이 있음 (예: 로컬 도구 우선 → npx fallback)

토큰 절약 + 신뢰성 확보. 예시:
- `mmdraw/scripts/render.sh` — Mermaid → PNG 렌더링 (mmdc → npx fallback)
- `rpc-agent/scripts/cosmos_total_tx.py` — 블록 순회 트랜잭션 집계

### When to Add Assets

다음에 해당되면 `assets/`로:
- 매번 같은 템플릿을 생성할 때 (YAML, JSON, Markdown 템플릿)
- 정적 자원 (아이콘, 샘플 데이터)
- 변수 치환만 하는 boilerplate

스크립트와 차이: assets는 **데이터/템플릿**, scripts는 **실행 코드**.

### 안티패턴

- 스킬 만들자마자 `references/`, `scripts/`, `assets/` 모두 생성 → 빈 디렉토리는 노이즈. 필요해지면 그때 만든다.
- SKILL.md가 50줄인데 `REFERENCE.md`로 분리 → 과한 분할. SKILL.md 본문에 자연스럽게 들어가는 분량은 분리하지 않는다.
- `references/` 안에 또 `references/` 중첩 → 참조 깊이는 1단계 유지. 2단계 이상은 모델이 따라가지 못할 가능성.

---

## Description Requirements

description은 **에이전트가 스킬 로딩 여부를 결정하는 유일한 단서**. 시스템 프롬프트에 다른 모든 스킬과 함께 노출됨.

### 규칙

- 1024자 이내 (권장 80~250자)
- 3인칭으로 작성
- 첫 문장: 무엇을 하는가
- 둘째 문장: "Use when [구체적 트리거]" — 키워드, 컨텍스트, 파일 타입 명시

### 좋은 예

```yaml
description: Create new Claude Code skills with proper structure, progressive disclosure, and bundled resources. Use when the user wants to create, write, build, add, or scaffold a new skill, says "new skill", "make a skill", "skill 만들기", "스킬 추가".
```

- "무엇" 명확: skill 생성
- "Use when" 트리거: 동사 5개(create/write/build/add/scaffold) + 자연어 표현 4개
- 한국어 트리거도 포함됨

### 나쁜 예

```yaml
description: Helps with skills.
```

다른 스킬과 구분이 안 됨. 트리거 키워드가 없음.

### 우리 저장소의 description 길이 분포 (참고)

| 길이대 | 스킬 |
|--------|------|
| 73~95자 | ssh-ops, rpc-health, helm-ops, k8s-ops, k8s-security, db-ops, terraform-ops, ralph, argocd-ops, rpc-agent |
| 100~150자 | best-practice, compound, mmdraw |
| 200자+ | grill-me (외부 도입), write-a-skill |

→ ops 도구류는 짧아도 됨. 메타/productivity는 트리거 키워드 다양성이 필요해서 길어짐.

## Conventions (claude-ops-skills 전용)

### 디렉토리/네이밍

- 디렉토리명 = slash command명 (kebab-case): `/k8s-ops`
- 영문 소문자 + 하이픈만 사용

### Frontmatter

| 필드 | 필수/선택 | 비고 |
|------|----------|------|
| `name` | 필수 | 디렉토리명과 일치 |
| `description` | 필수 | "Use when ..." 포함 |
| `argument-hint` | 권장 | 인자 받는 스킬 |
| `allowed-tools` | 권장 | 사용하는 도구 명시 |

pre-commit 훅이 `name`, `description` 부재 시 커밋 차단.

### READ-ONLY 원칙

K8s/DB/SSH 작업 스킬은 조회만 허용. 변경 명령어는 텍스트로 안내만.
- K8s: get, describe, logs, top, exec(조회) 만 허용
- DB: SELECT, SHOW만
- 변경 작업 (apply/delete/scale/edit 등) 절대 금지

### 보안

- **로컬 경로 노출 금지**: `/Users/<id>/`, `/home/<id>/dev/` 등
- **실제 인프라명 노출 금지**: 클러스터명, 서비스명, 회사명 → `my-cluster`, `my-prod` 등 제네릭으로
- **kubeconfig 실제 파일명** 노출 금지 (clusters.yaml은 .gitignore)
- **공인 IP 하드코딩 금지** (private/localhost는 OK)
- **credentials 하드코딩 금지** (password, token, secret, api_key)

pre-commit 훅이 위 5개 항목 자동 검증 (`scripts/pre-commit.sh`).

### 커밋 메시지

영어 + Conventional Commits.
- `feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `refactor:`, `test:`
- scope: `feat(k8s-security): add RBAC audit`

## Review Checklist

작성 후 자가 검토. Claude에게 "이 SKILL.md를 review checklist 기준으로 검토해줘"라고 명시 요청 가능.

- [ ] 추론 자유도를 사용자와 합의 (가드레일형이면 floor + 위임 문구가, 절차 고정형이면 hard 제약·고정 순서가 본문에 반영됨)
- [ ] description에 "Use when ..." 트리거 명시
- [ ] description 80~250자 권장 범위
- [ ] SKILL.md 100줄 이내 (초과 시 REFERENCE.md/EXAMPLES.md/scripts/로 분리)
- [ ] frontmatter에 name, description 존재
- [ ] 디렉토리명과 frontmatter `name` 일치
- [ ] 시점 종속 정보 없음 ("올해", "최근", "현재 버전" 등 — 시간이 지나면 거짓이 됨)
- [ ] 용어 일관성 (한 스킬 안에서 같은 개념을 같은 단어로)
- [ ] 구체적 예시 포함 (추상적 설명만으로 끝내지 않음)
- [ ] 참조 깊이 1단계 (REFERENCE.md가 또 다른 파일을 참조하지 않음)
- [ ] READ-ONLY 규칙 적용 여부 명확 (해당 시)
- [ ] 보안 체크리스트 위반 없음 (로컬 경로, 인프라명, IP, credentials)
- [ ] README.md Skills 표 + Structure 섹션 업데이트
