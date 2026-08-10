---
name: write-a-skill
description: Create new Claude Code skills with proper structure, progressive disclosure, and bundled resources for the claude-ops-skills repository. Use when the user wants to create, write, build, add, or scaffold a new skill, says "new skill", "make a skill", "skill 만들기", "스킬 추가", or opens templates/project-skill-template.
---

# Write a Skill

claude-ops-skills 저장소에 새 스킬을 추가할 때 인터뷰식으로 작성을 가이드한다.
원본: github.com/mattpocock/skills/blob/main/skills/productivity/write-a-skill — 우리 컨벤션에 맞게 customize.

상세 규약, 보안 체크리스트, Review Checklist는 [REFERENCE.md](REFERENCE.md) 참조.

## Process

`/write-a-skill` 호출 직후 인터뷰 시작. 질문은 한 번에 하나씩, 코드베이스로 답할 수 있는 건 먼저 탐색해서 해결.

1. **요구사항 인터뷰** — 도메인, 입력 인자, 외부 도구, 변경 동반 여부, **추론 자유도**(아래 섹션 참조 — 사용자와 합의)
2. **본문 구조 선택** — 아래 두 패턴 중 택일
3. **초안 작성** — `skills/<kebab-case-name>/SKILL.md`
4. **자가 검토** — REFERENCE.md의 Review Checklist 통과 확인
5. **등록** — README.md Skills 표 + Structure 섹션에 한 줄 추가

## 추론 자유도 — 가드레일형 vs 절차 고정형 (사용자와 합의)

스킬은 모델 추론을 대체하는 엔진이 아니라 **가드레일**이다. 자유를 얼마나 줄지 **이탈 비용**으로 정하고 사용자와 합의한다:

- **가드레일형** — 읽기 전용·열린 분석 등 blast radius가 작을 때. 불변 조건만 고정하고 수단은 floor로("최소한 이건, 더 나으면 그걸") → "어떻게"는 모델 업데이트분이 흡수. 예: catchup, best-practice
- **절차 고정형** — K8s/서버/DB 운용 등 즉흥이 사고로 이어질 때. 허용/금지와 순서를 명시 고정. 예: k8s-ops, ssh-ops, db-ops

혼합이 흔하다 (안전은 고정 + 분석은 위임). 작성법 → [REFERENCE.md](REFERENCE.md)

## Body Structure — 두 패턴

### 패턴 A: Ops/도구 스킬 (4단)

외부 도구를 호출하는 운영 스킬. k8s-ops, ssh-ops, helm-ops 등.

```md
## Safety Rules     # 허용/금지 명령어, READ-ONLY 정책
## Arguments        # $ARGUMENTS 해석
## Operations       # 명령어 표 또는 단계별 절차
## Output Format    # 보고 형식
```

### 패턴 B: Productivity/메타 스킬 (3단)

작업 흐름 자체가 핵심. grill-me, write-a-skill, catchup 등.

```md
## Quick start      # 최소 동작 예시
## Workflows        # 단계별 절차
## Advanced         # See REFERENCE.md / EXAMPLES.md
```

## 모델이 이미 아는 건 쓰지 않는다 (2026-08 방침)

**공개 표준 지식을 스킬에 적어 넣지 않는다.** Deployment YAML 스펙, Helm 템플릿 문법, ArgoCD 설치 명령, PromQL 기본형 같은 건 모델이 이미 알고, 우리가 적어두면 **버전이 낡아 오히려 틀린 답의 근거**가 된다.

스킬에 남길 가치가 있는 것은 셋뿐이다:

| 남길 것 | 예 |
|---------|-----|
| **우리 환경의 결정사항** | "우리는 --context를 항상 명시한다", "local-path는 quota가 없다" |
| **가드레일 / 불변 조건** | READ-ONLY 강제, 직접 실행 금지, 근거 없는 단정 금지 |
| **판정 기준** | PVC 70/85/95% 임계치, severity 매핑 표 |

판단 기준: *"이걸 지우면 모델이 틀린 답을 내나, 아니면 똑같이 잘 하나?"* 똑같이 잘 하면 지운다.

> 2026-08-10에 이 기준으로 k8s-craft/helm-ops/argocd-ops/k8s-ops의 `references/` 5,773줄을 삭제했다.

## Length Rule (150줄)

- **SKILL.md ≤ 150줄** — progressive disclosure (매 호출마다 로딩 비용 최소화)
- 150줄을 넘으면 **먼저 지울 것부터 찾는다.** 위 기준으로 잘라내고도 넘칠 때만 분리.
- 상한을 쓰라는 뜻이 아니다. 자립적으로 동작할 만큼만 쓰고, 남는 여유는 다른 스킬로 위임하지 않고 **필요한 규칙을 인라인으로 적는 데** 쓴다.

## Structure (점진적 확장)

**기본은 SKILL.md 단일 파일.** 아래는 정말 필요할 때만.

```
skills/<kebab-case-name>/
├── SKILL.md           # 필수 (≤150줄)
├── REFERENCE.md       # 선택 — 방법론 상세 (표준 지식 아님)
├── references/        # 선택 — 방법론 토픽이 3개+ 일 때만
├── scripts/           # 선택 — 결정론적 작업 (검증, 렌더링, 파싱)
└── assets/            # 선택 — 템플릿/샘플 등 정적 자원
```

`references/`는 **방법론·정책**에만 쓴다 (예: best-practice의 출처 검증 절차, ralph의 판정 정책). 리소스 카탈로그·문법 레퍼런스 용도로는 만들지 않는다.

> 트리거 표 → [REFERENCE.md](REFERENCE.md) "Structure Patterns"

## Pairing with grill-me

설계가 모호할 땐 `/grill-me`로 결정 트리 정리 → 이 스킬로 들어옴.

## Detailed Guides

- Description 작성 규칙, 좋은/나쁜 예시 → [REFERENCE.md](REFERENCE.md)
- 보안 체크리스트, 컨벤션 → [REFERENCE.md](REFERENCE.md)
- Review Checklist (10개 항목) → [REFERENCE.md](REFERENCE.md)
