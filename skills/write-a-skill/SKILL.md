---
name: write-a-skill
description: Create new Claude Code skills with proper structure, progressive disclosure, and bundled resources for the claude-ops-skills repository. Use when the user wants to create, write, build, add, or scaffold a new skill, says "new skill", "make a skill", "skill 만들기", "스킬 추가", or opens templates/project-skill-template.
---

# Write a Skill

claude-ops-skills 저장소에 새 스킬을 추가할 때 인터뷰식으로 작성을 가이드한다.
원본: github.com/mattpocock/skills/blob/main/skills/productivity/write-a-skill — 우리 컨벤션에 맞게 customize.

상세 규약, 보안 체크리스트, Review Checklist는 [REFERENCE.md](REFERENCE.md) 참조.

## Quick start

```
/write-a-skill
```

호출 직후 인터뷰가 시작됨. 한 번에 하나씩 답해주면 됨.

## Process

질문은 한 번에 하나씩. 답변 가능한 건 코드베이스 탐색으로 먼저 해결.

1. **요구사항 인터뷰** — 도메인, 입력 인자, 외부 도구, 변경 동반 여부, **추론 자유도**(아래 섹션 참조 — 사용자와 합의)
2. **본문 구조 선택** — 아래 두 패턴 중 택일
3. **초안 작성** — `skills/<kebab-case-name>/SKILL.md`
4. **자가 검토** — REFERENCE.md의 Review Checklist 통과 확인
5. **등록** — README.md Skills 표 + Structure 섹션에 한 줄 추가

## 추론 자유도 — 가드레일형 vs 절차 고정형 (사용자와 합의)

스킬은 모델 추론을 대체하는 엔진이 아니라 **가드레일을 한 번 더 잡아주는 것**이다. 모델이 업데이트되며 좋아지는 건 대부분 "어떻게 추론하나"이므로, 거기에 자유를 얼마나 줄지 **이탈 비용**으로 정하고 사용자와 합의한다:

- **가드레일형 (추론 위임)** — 읽기 전용·열린 분석 등 모델 즉흥의 blast radius가 작을 때. 출처·수단은 floor("최소한 이건, 더 나으면 그걸")로만, 불변 조건만 고정 → "어떻게"는 모델 업데이트분이 흡수. 예: catchup, best-practice
- **절차 고정형** — K8s/서버/DB 운용 등 즉흥이 write·사고로 이어질 때. 허용/금지 명령·순서를 명시 고정, 이탈 금지. 예: k8s-ops, ssh-ops, db-ops

md 레이아웃(아래 두 패턴)과는 다른 축 — ralph는 Productivity 레이아웃이나 고정 루프라 절차 고정형. 혼합도 흔하다(안전은 고정 + 분석은 위임). 작성법 → [REFERENCE.md](REFERENCE.md)

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

작업 흐름 자체가 핵심. grill-me, ralph, write-a-skill, compound 등.

```md
## Quick start      # 최소 동작 예시
## Workflows        # 단계별 절차
## Advanced         # See REFERENCE.md / EXAMPLES.md
```

## Length Rule (100줄)

- **SKILL.md ≤ 100줄** — progressive disclosure (매 호출마다 로딩 비용 최소화)
- 100줄 초과 시 분리. 분리 단위는 [REFERENCE.md](REFERENCE.md) "Structure Patterns" 참조.

## Structure (점진적 확장)

기본은 SKILL.md 단일 파일. **필요할 때만** 디렉토리/파일 추가.

```
skills/<kebab-case-name>/
├── SKILL.md           # 필수 (≤100줄)
├── REFERENCE.md       # 선택 — 단일 상세 문서 (1~2개 토픽)
├── references/        # 선택 — 토픽별 분리 (3개+ 도메인)
│   ├── networking.md
│   ├── storage.md
│   └── troubleshooting.md
├── scripts/           # 선택 — 결정론적 작업 (검증, 렌더링, 파싱)
│   └── render.sh
└── assets/            # 선택 — 템플릿/샘플/아이콘 등 정적 자원
    └── deployment.yaml.tpl
```

> 무엇을 언제 추가하는지(REFERENCE.md / references/ / scripts/ / assets/) 트리거 표 → [REFERENCE.md](REFERENCE.md) "Structure Patterns"

**원칙**: 시작은 SKILL.md만, 구조는 **필요해질 때 점진적으로 확장**. references/가 3개+면 SKILL.md에 "어떤 상황에 어떤 파일을 로드"하는 표를 둔다.

## Pairing with grill-me

설계가 모호할 땐 `/grill-me`로 결정 트리 정리 → 이 스킬로 들어옴.

## Detailed Guides

- Description 작성 규칙, 좋은/나쁜 예시 → [REFERENCE.md](REFERENCE.md)
- 보안 체크리스트, 컨벤션 → [REFERENCE.md](REFERENCE.md)
- Review Checklist (10개 항목) → [REFERENCE.md](REFERENCE.md)
