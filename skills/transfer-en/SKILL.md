---
name: transfer-en
description: Translate Korean to easy conversational English (CEFR A2 level) for Korean users learning English through real-world use. Use when the user wants to translate Korean to English with simple words, casual tone, and learning hints. Triggers - "/transfer-en", "영어로 번역", "쉬운 영어로", "translate to English". Output includes translation + casual alternative + learning point (when valuable).
argument-hint: <한국어 문장>
allowed-tools: Read, Write, Edit
---

# transfer-en

한국어 → **쉬운 대화체 영어** (CEFR A2). 회사 Slack/이메일 + 기술 문서 톤.

## Quick start

```
/transfer-en 오늘 회의 30분 늦어질 것 같아
/transfer-en --review        # public/pending.md 검토 후 public/learning.md로 이관
```

사용자 데이터는 모두 `public/` 서브폴더 (gitignore 처리, 로컬 전용).

## Translation Rules

1. **어휘**: 일상 회화 1500~2500 단어. 어려운 단어 회피
2. **문법**: 현재/과거/미래, 기초 조동사(will/can/should), if 1형식까지. 가정법/분사구문 회피
3. **톤**: 회화체 (I'm/gonna 줄임말 OK). 안전한 캐주얼만 (Hey/Cool/Got it)
4. **직역 vs 의역**: 직역 어색하면 의역 (예: "수고하셨습니다" → "Good job today")

## Output Format

```
🇰🇷 <원문>

🇺🇸 번역
<A2 수준 표준 번역>

🔄 더 캐주얼하게
<짧고 자연스러운 동료/친구 톤>

💡 학습 포인트 (가치 있을 때만)
- "<표현>" : <뜻>
  → 사용 상황: <언제 쓰는지>
```

**학습 포인트 조건**:
- 단순 인사/감사 (Hi, Thanks) → 생략
- phrasal verb, idiom, 한국어 직역 안 되는 패턴 → **반드시 추가**
- `public/learning.md`에 있는 표현 → 생략
- 핵심 동사 활용 (have/get/take/put 등) 첫 등장 → 추가

## Learning Note System

학습 누적은 2단계 파일 (모두 `public/` 안, gitignore).

| 파일 | 역할 | 작성자 |
|------|------|--------|
| `public/pending.md` | 자동 누적 버퍼 | 스킬 (자동) |
| `public/learning.md` | 검토 후 영구 노트 | 사용자 (수동/--review) |

### 동작

1. **번역 시**: 학습 포인트 → `public/pending.md`에 append (날짜 + 표현 + 뜻 + 상황)
2. **번역 전**: `public/learning.md` 읽기 → 거기 있는 표현은 학습 포인트 생략
3. **pending.md ≥ 10개**: 번역 끝에 안내
   ```
   📚 public/pending.md에 10개 누적. /transfer-en --review 로 정리하세요.
   ```
4. **`--review`**: pending 항목 카테고리별 제시 → 사용자가 선택 → 선택분만 `public/learning.md`로 이관 → `public/pending.md` 비움

심링크 설치이므로 모든 프로젝트에서 동일 파일에 누적됨.

## Level System

`public/level.md` 기반 점진적 수준 상향. 매 번역 시 현재 Stage 참조 → 어휘/문법 범위 결정. `--review`에서 마일스톤 충족 시 사용자 승인 후 상향. **상세는 [levelup.md](levelup.md) 참조**.

| Stage | 수준 | 진입 조건 (요약) |
|-------|------|---------------|
| 1 | A2 기초 | 기본값 |
| 2 | A2+ | phrasal verb 5+, 전치사 3쌍+ 마스터 |
| 3 | B1 | + 시제 표현 5+ 마스터 |
| 4 | B1+ | + 관계대명사/가정법 3+ 마스터 |

## Files

```
skills/transfer-en/
├── SKILL.md          # 시스템 (이 파일, git 추적)
├── levelup.md        # Stage/리뷰 상세 (git 추적)
└── public/           # 사용자 데이터 (gitignore, 로컬 전용)
    ├── pending.md    # 자동 누적 버퍼
    ├── learning.md   # 카테고리별 영구 학습 노트
    └── level.md      # 현재 Stage + Mastered + Focus + History
```

## Scope

- ✅ 한국어 → 영어 (회화체), 학습 포인트 자동 추출
- ❌ 영어 → 한국어 (역방향 X), 긴 글 통째 번역 (1~3 문장 권장)
