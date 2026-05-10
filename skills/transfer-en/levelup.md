# Level Up System

주간 리뷰 + 점진적 수준 상향 시스템. SKILL.md 본문에서 분리한 상세 가이드.

## Stage 정의

CEFR 기반 4단계. 번역 시 현재 Stage에 맞춰 어휘/문법 범위 조정.

| Stage | 수준 | 진입 조건 | 번역 시 변화 |
|-------|------|----------|-------------|
| 1 | A2 기초 | 기본값 (시작) | phrasal verb 회피, 직역 가능 표현 우선, 단순 문장 |
| 2 | A2+ | phrasal verbs 5+ 마스터, prepositions 차이 3쌍+ 정리 | 자주 쓰는 phrasal verb 적극 사용 (get back to, look into 등) |
| 3 | B1 진입 | Stage 2 + 시제 다양화 표현 5+ 마스터 | 현재완료/진행형, if 2형식, 의문문 다양화 사용 |
| 4 | B1+ | Stage 3 + 관계대명사/가정법 기초 표현 3+ 마스터 | 관계대명사(which/who), 가정법 기초, 자연스러운 복문 |

"마스터"의 정의: `public/learning.md`에 사용자가 직접 이관한 항목. public/pending.md 항목은 카운트하지 않음 (사용자가 검토/승인한 것만 실력으로 인정).

## level.md 포맷 (`public/level.md`)

```markdown
# Current Level

**Stage**: 1 (A2 기초)
**Last review**: 2026-05-10
**Reviews completed**: 0

## Mastered Categories

### Phrasal Verbs (0)
(아직 없음)

### Prepositions (0)
(아직 없음)

### Core Verbs (0)
(아직 없음)

### Tenses (0)
(아직 없음)

## Active Focus (이번 주)

- 기본 동사 활용 (have/get/take/put/make)
- 전치사 차이 (before/until, at/in/on, for/during)

## Next Stage Trigger

**현재 → Stage 2 (A2+)**:
- [ ] Phrasal Verbs 카테고리에 5개+ 정리
- [ ] Prepositions 카테고리에 3쌍+ 정리

## History

- 2026-05-10: Stage 1 시작
```

## 매 번역 시 동작

1. `public/level.md` 읽기 → 현재 Stage 확인
2. Stage에 맞춰 번역 어휘/문법 결정
3. `Mastered Categories`에 있는 표현은 학습 포인트 생략 (이미 안다고 간주)
4. `Active Focus` 영역과 관련된 표현은 학습 포인트 우선 추가

## --review 주간 리뷰 플로우

`/transfer-en --review` 호출 시:

### 1단계: pending → learning 이관 (기존 동작)
- public/pending.md 항목을 카테고리별로 묶어 사용자에게 제시
- 사용자가 선택 → 선택분만 public/learning.md로 이관 → public/pending.md 비움

### 2단계: 통계 분석
- public/learning.md를 카테고리별 카운트
- public/level.md의 Mastered Categories 갱신

### 3단계: 수준 평가
- 다음 Stage 트리거 충족 여부 확인
- **충족 시**: 사용자에게 승인 요청 (자동 상향 X)
  ```
  🎉 Stage 2 (A2+) 진입 가능!
  - Phrasal Verbs 7개 마스터 (트리거: 5+)
  - Prepositions 4쌍 마스터 (트리거: 3+)

  Stage 2로 올릴까요? (y/n)
  - y → 다음 번역부터 phrasal verb 적극 사용
  - n → Stage 1 유지 (조금 더 안정화)
  ```
- **미충족 시**: 진척도만 표시
  ```
  📊 Stage 2까지 남은 진척도:
  - Phrasal Verbs: 3/5 (2개 더 필요)
  - Prepositions: 1/3 (2쌍 더 필요)
  ```

### 4단계: 다음 주 Active Focus 제안
- public/pending.md/public/learning.md에서 **자주 등장한 카테고리** 분석
- 약한 영역 또는 다음 Stage 트리거 카테고리를 Active Focus로 제안
- 사용자가 OK 하면 public/level.md의 Active Focus 갱신

### 5단계: public/level.md 업데이트
- Last review 날짜
- Reviews completed +1
- History에 한 줄 추가 (예: "2026-05-17: Phrasal Verbs 4→7, Stage 1 유지")

## Stage 다운그레이드

자동 다운그레이드 없음. 사용자가 "너무 어려워, Stage 1로 돌아가자"라고 명시하면 수동 조정.

## 학습 카테고리 (`public/learning.md` 섹션 매핑)

| 카테고리 | learning.md 섹션 | Stage 트리거 관련 |
|---------|----------------|-----------------|
| Phrasal Verbs | `## Phrasal Verbs` | Stage 2 |
| Prepositions | `## Prepositions` | Stage 2 |
| Core Verbs | `## Core Verbs (have / get / take / put / make ...)` | (Active Focus) |
| Tenses | `## Tenses` (신규) | Stage 3 |
| Relative/Conditional | `## Grammar Patterns` | Stage 4 |
| Idioms | `## Idioms / Expressions` | (Active Focus) |
