---
name: mmdraw
description: Analyze source code or docs and generate validated Mermaid diagrams. Use when the user wants to visualize architectures, workflows, or sequences.
argument-hint: "<analysis target or diagram description>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

# mmdraw

소스 코드나 문서를 분석하여 **문법 에러 없는** Mermaid 다이어그램을 생성한다.
생성된 `.mmd` 파일은 https://mermaid-to-excalidraw.vercel.app/ 에서 Excalidraw로 변환 가능.

문법 규칙, 에러 해결법은 [REFERENCE.md](REFERENCE.md) 참조.

## Workflow

### 1. 분석

`$ARGUMENTS`를 파악하여 대상을 결정한다.

- 파일/디렉토리 경로 → 소스 코드 분석
- `.md` 파일 → 문서 분석
- 텍스트 설명 → 설명 기반 생성

핵심 파악 대상: 컴포넌트/서비스 목록과 역할, 데이터 흐름 방향과 프로토콜, 의존 관계와 실행 순서, 외부 접점(Ingress, API, 사용자).

### 2. 다이어그램 유형 선택

| 유형 | 용도 | 선언 |
|------|------|------|
| **Flowchart** | 아키텍처, 데이터 흐름, 의존 관계 | `flowchart TB` 또는 `flowchart LR` |
| **Sequence** | 시간 순서, API 호출, 부팅 순서 | `sequenceDiagram` |

하나의 `.mmd` 파일에 다이어그램 하나만. 여러 관점이 필요하면 파일 분리.

### 3. Mermaid 생성

[REFERENCE.md](REFERENCE.md)의 문법 규칙을 반드시 따른다.

### 4. 검증

생성 후 아래 체크리스트를 통과해야 저장한다. 위반 시 수정 후 재검증.

#### 구조
- [ ] 다이어그램 유형 선언이 첫 줄 (`flowchart TB`, `sequenceDiagram`)
- [ ] 모든 `subgraph` / `alt` / `loop` / `rect` 블록이 `end`로 닫힘

#### 노드 ID
- [ ] 공백, 하이픈, 특수문자, 한글 없음 (영문+숫자+`_` 만)
- [ ] Mermaid 예약어 아님 (`end`, `subgraph`, `click`, `style`, `class`, `default`)
- [ ] 같은 ID가 다른 의미로 중복 사용되지 않음

#### 엣지 & 라벨
- [ ] 엣지 라벨이 큰따옴표로 감싸짐 (`-- "label" -->`)
- [ ] 라벨 안에 큰따옴표 없음 (작은따옴표로 대체)
- [ ] 화살표 문법 정확 (`-->`, `---`, `-.-`, `-.->`, `==>`)
- [ ] 참조 노드 ID가 실제 정의됨

#### Sequence 전용
- [ ] `participant` 선언이 다이어그램 상단
- [ ] 메시지 문법 정확 (`->>`, `-->>`, `->`, `-->`)
- [ ] `Note over`의 participant 이름 정확

#### 특수 문자
- [ ] `()`, `[]`, `{}`, `<>`, `:` 포함 라벨은 따옴표로 감쌈
- [ ] `&`, `|` 미사용 (HTML entity 필요)

### 5. 저장

`.mmd` 파일로 저장하고 변환 안내를 출력:

```
📄 <filename>.mmd 저장 완료
🖼  <filename>.png 렌더링 완료
→ 편집 필요 시 https://mermaid-to-excalidraw.vercel.app/ 에서 Excalidraw 변환 가능
```

### 6. PNG 렌더링

`.mmd`와 같은 경로에 `.png`도 생성. `scripts/render.sh`를 사용한다.

```bash
${CLAUDE_SKILL_DIR}/scripts/render.sh <file>.mmd
```

스크립트가 로컬 `mmdc` → `npx` fallback을 자동 처리. 옵션은 `--width`(기본 1400), `--bg`(기본 white).
첫 npx 실행은 puppeteer + Chromium 다운로드로 60~120초 → Bash timeout 180s 이상.
실패 시 `.mmd`만이라도 남기고 사용자에게 사유 보고.

## 출력 규칙

- 파일 확장자: `.mmd`
- 파일 하나에 다이어그램 하나
- 파일명은 내용 반영: `auth-flow.mmd`, `k8s-architecture.mmd`
- 저장 경로: `docs/diagrams/` (없으면 `mkdir -p`)
- Markdown 코드 펜스 없이 순수 Mermaid 문법만 저장
- `.mmd`와 짝을 이루는 `.png` 동일 경로에 생성 (렌더 실패 시 `.mmd`만 남김)
