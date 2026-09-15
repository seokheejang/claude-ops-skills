---
name: transfer-en
description: Translate Korean to natural, simple English for a Korean speaker with standard school-level English. Plain words, short sentences, nothing that reads awkward to a native speaker. Use when the user wants Korean translated to English for Slack, email, or technical writing. Triggers - "/transfer-en", "영어로 번역", "쉬운 영어로", "translate to English".
argument-hint: <한국어 문장>
allowed-tools: Read
---

# transfer-en

한국어 → **간결하고 자연스러운 영어**. 회사 Slack·이메일과 기술 문서 톤.

```
/transfer-en 오늘 회의 30분 늦어질 것 같아
```

## 수준 기준

사용자는 **한국에서 정규 영어 교육을 받은 수준**이다. 목표는 둘을 동시에 만족하는 것이다.

1. **읽고 바로 이해할 수 있을 것** — 사전을 찾아야 하는 단어를 쓰지 않는다
2. **원어민이 봤을 때 어색하지 않을 것** — 쉽게 쓰되 틀리거나 부자연스럽게 쓰지 않는다

둘이 충돌하면 **2번이 이긴다.** 쉬운 단어로 어색한 문장을 만드는 것보다, 약간 덜 익숙해도 자연스러운 표현을 쓰는 편이 낫다. 대신 그 표현은 학습 포인트로 짚어준다.

## 번역 규칙

- **문장을 짧게 끊는다.** 한국어 한 문장이 길면 영어로는 두 문장으로 나눈다
- **직역이 어색하면 의역한다** — 예: "수고하셨습니다" → "Good job today" / "Thanks for the work today"
- **줄임말(I'm, gonna, don't)은 쓴다.** 회사 동료에게 보내는 톤이다
- **기술 용어·고유명사·명령어·에러 메시지는 번역하지 않는다**
- 과한 격식(Dear, I would like to kindly request)도, 과한 캐주얼(slang, 은어)도 피한다

## Output Format

```
🇰🇷 <원문>

🇺🇸 <번역>

🔄 더 캐주얼하게
<짧고 자연스러운 동료 톤. 위 번역과 톤 차이가 없으면 생략>

💡 <표현> : <뜻> — <언제 쓰는지>
```

**번역문 앞에 `▎`, `|`, `>` 같은 인용·장식 문자를 붙이지 않는다.** 사용자가 그대로 복사해서 Slack·이메일에 붙여넣는다. 평문 한 줄로만 출력한다.

**학습 포인트(💡)는 가치 있을 때만 한두 줄.** phrasal verb, idiom, 한국어로 직역되지 않는 패턴일 때 넣는다. 단순 인사·감사(Hi, Thanks, Got it)에는 넣지 않는다.

## Scope

- ✅ 한국어 → 영어, 1~3문장 단위
- ❌ 영어 → 한국어 (역방향), 긴 글 통째 번역
