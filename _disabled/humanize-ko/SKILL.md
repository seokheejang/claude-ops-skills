---
name: humanize-ko
description: Rewrite AI-generated Korean text to read like a human wrote it — adjusting style, rhythm, and phrasing while keeping the content 100% unchanged. Use when the user wants to remove the "AI tone" from Korean writing, says "AI 티 없애줘", "윤문해줘", "사람이 쓴 것처럼", "humanize", or "/humanize-ko". Detects fixed AI-tell patterns and applies surgical edits without touching facts, numbers, proper nouns, or direct quotes.
argument-hint: <윤문할 한국어 글 또는 파일 경로>
allowed-tools: Read, Write, Edit
---

# humanize-ko

AI(ChatGPT·Claude·Gemini 등)가 쓴 한국어 글을 **내용은 한 글자도 바꾸지 않고** 문체·리듬·표현만 사람이 쓴 것처럼 되돌린다.

> 영감: [epoko77-ai/im-not-ai](https://github.com/epoko77-ai/im-not-ai) (MIT, `/humanize`). 아이디어만 차용, 패턴·구조는 이 repo 컨벤션에 맞춰 직접 작성.

## Quick start

```
/humanize-ko 우리는 다양한 측면에서 이 문제를 살펴볼 필요가 있습니다. ...
/humanize-ko docs/draft.md          # 파일 경로도 가능
```

1~2 문단이면 즉시 윤문. 긴 글은 문단 단위로 나눠 처리.

## 불변 조건 (절대 위반 금지)

이건 모델 판단에 맡기지 않는다 — **고정 제약**이다.

1. **내용 보존**: 사실·주장·논리 순서·숫자·고유명사·**직접인용("...")**은 100% 그대로. 윤문은 표현·문장구조·연결만 건드린다.
2. **장르·격식 유지**: 보고서는 보고서 톤, 캐주얼은 캐주얼 톤. 격식 수준을 임의로 바꾸지 않는다.
3. **변경률 감시**: 원문 대비 35% 넘게 고쳤으면 경고하고, 어디를 왜 그만큼 바꿨는지 보고. 50% 넘으면 "이건 윤문이 아니라 재작성"이라고 알리고 사용자 확인을 받는다.
4. **자동 파일 로딩 금지**: 인자로 받은 글/파일만 처리. CLAUDE.md 등 프로젝트 설정을 임의로 끌어오지 않는다.

## Workflow

1. **탐지** — [references/patterns.md](references/patterns.md)의 9개 카테고리·세부 변종(A1, A2 …)을 순서대로 훑어 AI 티 지점을 표시. 처방 감을 잡으려면 [references/examples.md](references/examples.md)의 변종별 before→after를 같이 본다. 각 지점에 변종 태그와 심각도(S1 치명/S2 거슬림/S3 사소)를 단다.
2. **윤문** — 심각도 높은 것부터 처방대로 고침. 불변 조건 4개를 매 문장 점검.
3. **검수** — 고친 글을 원문과 대조: ① 사실/숫자/고유명사/인용 누락·변형 없는지 ② 변경률 ③ 장르 유지. 위반 시 해당 부분 되돌림.
4. **출력** — 아래 형식.

## AI 티 패턴 — 9개 카테고리

| 태그 | 카테고리 | 한 줄 요약 |
|------|----------|-----------|
| A | 번역 말투 | 영어 직역체 ("~에 대해", "~을 가지다", 무생물 주어) |
| B | 기계적 병렬 | 똑같은 구조 문장 반복, 과한 "첫째/둘째/셋째" |
| C | 접속·연결 과다 | "또한·게다가·뿐만 아니라" 남발, 문장마다 접속사 |
| D | 상투적 마무리 | "결론적으로", "~하는 것이 중요합니다", 요약 강박 |
| E | 과한 헤지·격식 | "~인 것 같습니다", "일반적으로", 불필요한 완충 표현 |
| F | 수동태·명사화 과다 | "~되어집니다", "~에 대한 검토가 이루어졌다" |
| G | 리듬 단조 | 문장 길이가 다 비슷, 호흡 변화 없음 |
| H | 장식 과잉 | 불릿·이모지·볼드 남용, 강조를 위한 강조 |
| I | AI 특유 표현 | "살펴보겠습니다", "~라고 할 수 있습니다", 빈 메타 문장 |

### Reference Guide

| 파일 | 내용 | 로드 시점 |
|------|------|----------|
| [references/patterns.md](references/patterns.md) | 카테고리별 탐지 신호 + 처방 | 탐지·윤문 시 항상 |
| [references/examples.md](references/examples.md) | 세부 변종별 before→after 예시 (전체) | 처방 감 잡을 때, 애매할 때 |

## Output Format

```
✏️ 윤문 결과
<고친 글 — 평문, 그대로 복사 가능하게>

📋 변경 요약
- [A2 ~에 대해/S2] "X에 대해 살펴보면" → "X를 보면"
- [D1 결산 피벗/S1] 마지막 "결론적으로 ~중요합니다" 문장 삭제 (내용 중복)
- ...

📊 변경률: 약 NN% (35% 이하 정상 / 초과 시 사유)
```

**중요**: 윤문 결과 앞에 `▎`, `|`, `>` 같은 인용·장식 문자를 붙이지 말 것. 사용자가 바로 복사할 수 있어야 함.

## Scope

- ✅ AI가 쓴 한국어 글 윤문 (내용 보존), AI 티 지점 진단·근거 제시
- ❌ 내용 자체 수정·팩트체크·번역, 영어 글, 처음부터 새로 쓰기(재작성)
