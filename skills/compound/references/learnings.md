# compound — Learnings Reference

학습 기록(`docs/learnings/`) 정책 상세. compound 워크플로 3단계 (B).

## 기록 대상 (persist)

작업 중 발견한 **비자명(non-obvious)한 인사이트**:

- 삽질 후 발견한 해결법 (에러 원인 + 해결 과정)
- 도구/라이브러리의 문서화되지 않은 한계
- 비직관적인 패턴이나 규칙
- 의사결정 근거 (왜 A를 선택하고 B를 버렸는가)
- 반복될 수 있는 실수와 예방법

## 스킵 대상 (discard)

- 단순 설정 변경 (config 값 수정)
- 코드에서 바로 읽히는 자명한 내용
- 일회성 작업 (다시 발생하지 않을 것)
- 이미 `docs/learnings/`에 유사 내용이 있는 것

## 파일 구조 정책 (CRITICAL — append-first)

학습마다 새 파일을 만들면 안 된다. 검색/탐색 비용이 빠르게 커진다.
아래 의사결정 트리를 **반드시** 따른다.

```
새 학습이 발생했다
├─ docs/learnings/ 에 같은 도메인/도구의 파일이 있는가?
│  ├─ YES → 그 파일에 새 섹션(### YYYY-MM-DD <소제목>) 으로 append
│  └─ NO  → 도메인 단위 파일을 신규 생성 (예: helm.md, geth.md, k8s.md)
└─ 단일 파일이 너무 커졌는가? (대략 600줄 또는 섹션 15개 초과)
   └─ YES → 카테고리/하위토픽으로 분리 (예: helm.md → helm/ingress.md, helm/release.md)
```

### 파일명 규칙

- 1단계: 도메인 단위 단일 파일 (`helm.md`, `geth.md`, `mermaid.md`)
- 2단계 (분리 후): 디렉토리 + 하위토픽 (`helm/ingress.md`, `helm/release.md`)
- **금지**: `helm-ingress-dual-format.md`, `helm-set-string-vs-set.md` 처럼 학습 단위로 파일을 쪼개지 않는다

### 파일 내부 구조 (도메인 파일)

```markdown
# <Domain> Learnings

이 파일의 목차를 자동 갱신하지 않아도 됨. 시간순으로 append.

---

## YYYY-MM-DD — <짧은 제목>

**Category**: <syntax|architecture|tooling|debugging|convention>
**Related**: <관련 파일, 스킬, 명령어>

### 컨텍스트
<어떤 상황>

### 내용
<핵심 학습. 코드/명령어 예시 포함.>

### 왜 중요한가
<다음에 어떻게 도움이 되는가>

---

## YYYY-MM-DD — <다음 학습>
...
```

### 기존 파일 append 규칙

- 파일 끝에 `---` 구분선 + 새 `## YYYY-MM-DD — <제목>` 섹션 추가
- 기존 섹션은 절대 수정하지 않음
- 동일 날짜에 여러 학습이면 별도 섹션으로 각각 추가

## 분리(splitting) 트리거

다음 조건 중 하나라도 해당하면:
- 단일 파일이 600줄 초과
- `## YYYY-MM-DD` 섹션이 15개 초과

→ 출력에 `⚠ <file>.md splitting recommended` 경고를 띄우고 사용자에게 분리 제안.
**사용자 승인 없이 자동 분리하지 않는다** (기존 링크/참조 깨질 수 있음).

## 마이그레이션 (기존 분산 파일 정리)

이미 `helm-*.md`, `geth-*.md` 같이 학습 단위로 파일이 쪼개진 상태라면:

- 즉시 합치지 말고, 출력에 `⚠ <prefix>-*.md N개 파일 → <prefix>.md 통합 제안` 만 표시
- 사용자 승인 후 별도 작업으로 통합

## CLAUDE.md Discoverability 안내 템플릿

프로젝트 `CLAUDE.md`에 학습 디렉토리 안내가 없을 때 추가 **제안**용 텍스트:

```markdown
## Learnings

작업 중 발견한 패턴, 해결법, 의사결정 근거는 `docs/learnings/`에 축적됨.
새 작업 시작 전 관련 학습 기록이 있는지 확인하면 삽질을 줄일 수 있음.
```
