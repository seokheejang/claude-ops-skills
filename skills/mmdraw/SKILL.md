---
name: mmdraw
description: Analyze source code or docs and generate validated Mermaid diagrams. Use when the user wants to visualize architectures, workflows, or sequences.
argument-hint: "<analysis target or diagram description>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

# draw

소스 코드나 문서를 분석하여 **문법 에러 없는** Mermaid 다이어그램을 생성한다.
생성된 `.mmd` 파일은 https://mermaid-to-excalidraw.vercel.app/ 에서 Excalidraw로 변환 가능.

## Workflow

### 1. 분석
`$ARGUMENTS`를 파악하여 대상을 결정한다.

- 파일/디렉토리 경로 → 소스 코드 분석
- `.md` 파일 → 문서 분석
- 텍스트 설명 → 설명 기반 생성

분석 시 핵심 파악 대상:
- 컴포넌트/서비스 목록과 역할
- 데이터 흐름 방향과 프로토콜
- 의존 관계와 실행 순서
- 외부 접점 (Ingress, API, 사용자)

### 2. 다이어그램 유형 선택

| 유형 | 용도 | 선언 |
|------|------|------|
| **Flowchart** | 아키텍처, 데이터 흐름, 의존 관계 | `flowchart TB` 또는 `flowchart LR` |
| **Sequence** | 시간 순서, API 호출, 부팅 순서 | `sequenceDiagram` |

하나의 `.mmd` 파일에 다이어그램 하나만 포함한다. 여러 관점이 필요하면 파일을 분리한다.

### 3. Mermaid 생성

아래 **문법 규칙**을 반드시 따른다.

### 4. 검증

생성 후 아래 **검증 체크리스트**를 통과하는지 확인한다.
에러가 예상되면 수정 후 저장한다.

### 5. 출력

`.mmd` 파일로 저장하고, 변환 안내를 출력한다:

```
📄 <filename>.mmd 저장 완료
→ https://mermaid-to-excalidraw.vercel.app/ 에서 Excalidraw 변환 가능
```

---

## Flowchart 문법 규칙

### 선언

```
flowchart TB    ← 위→아래 (아키텍처, 계층 구조)
flowchart LR    ← 왼→오른 (파이프라인, 시간 흐름)
```

`graph`가 아닌 **`flowchart`**를 사용한다. `graph`는 일부 기능을 지원하지 않는다.

### 노드

| 형태 | 문법 | 용도 |
|------|------|------|
| 사각형 | `ID["Label"]` | 기본 컴포넌트 |
| 원통형 | `ID[("Label")]` | 데이터베이스, PVC, 스토리지 |
| 육각형 | `ID{{"Label"}}` | Secret, ConfigMap |
| 원형 | `ID(("Label"))` | 외부 액터, 시작/끝점 |
| 다이아몬드 | `ID{"Label"}` | 조건 분기 |
| 둥근 사각형 | `ID("Label")` | 프로세스, 서비스 |

**노드 ID 규칙:**
- 영문+숫자+언더스코어만: `GETH`, `LH_PVC`, `user1` ✅
- 공백, 특수문자, 한글 금지: `my node`, `k8s-pod` ❌
- 하이픈 쓰려면 ID와 라벨 분리: `K8S_POD["k8s-pod"]` ✅
- Mermaid 예약어 금지: `end`, `subgraph`, `click`, `style` ❌

### 엣지 (화살표/선)

| 형태 | 문법 | 용도 |
|------|------|------|
| 화살표 | `A --> B` | 방향 있는 연결 |
| 라벨 화살표 | `A -- "label" --> B` | 설명 있는 연결 |
| 선 (방향 없음) | `A --- B` | 연관 관계 |
| 점선 | `A -.- B` | 약한 연결, 공유 참조 |
| 점선 화살표 | `A -.-> B` | 약한 방향 연결 |
| 굵은 화살표 | `A ==> B` | 강조 연결 |
| 양방향 | `A <-- "label" --> B` | 양방향 통신 |

**라벨 규칙:**
- 라벨은 반드시 큰따옴표로 감싼다: `-- "label" -->` ✅
- 따옴표 없이 쓰면 파싱 에러 위험: `-- label -->` ❌
- 라벨 안에 큰따옴표 사용 금지. 작은따옴표로 대체: `-- "Engine API '8551'" -->` ✅
- 콜론 포함 시 반드시 따옴표: `-- "port :8545" -->` ✅

### Subgraph

```mermaid
subgraph ID["Display Name"]
    %% 내용
end
```

**규칙:**
- ID와 표시명을 분리한다: `subgraph EL["Execution Layer"]` ✅
- ID에 공백/특수문자 금지: `subgraph "Execution Layer"` ❌
- 반드시 `end`로 닫는다
- 중첩 가능 (subgraph 안에 subgraph)
- subgraph 밖에서 안의 노드를 참조 가능

---

## Sequence 다이어그램 문법 규칙

### 선언

```
sequenceDiagram
```

### Participant

```
participant ID as Display Name
```

- `participant`를 먼저 선언하면 순서가 보장된다
- 선언하지 않으면 등장 순서대로 배치된다

### 메시지 (화살표)

| 형태 | 문법 | 용도 |
|------|------|------|
| 실선 화살표 | `A->>B: message` | 요청, 호출 |
| 점선 화살표 | `A-->>B: message` | 응답, 비동기 |
| 실선 (화살표 없음) | `A->B: message` | 단순 메시지 |
| 점선 (화살표 없음) | `A-->B: message` | 약한 메시지 |
| X 표시 (실패) | `A-xB: message` | 실패, 거부 |

### Note

```
Note over A: single participant
Note over A,B: spanning two participants
Note right of A: positioned right
Note left of A: positioned left
```

### 블록

```
rect rgb(200, 220, 255)
    A->>B: grouped action
end

alt condition
    A->>B: if true
else other
    A->>C: if false
end

loop description
    A->>B: repeated
end
```

---

## 검증 체크리스트

생성 후 반드시 아래 항목을 확인한다:

### 구조
- [ ] 다이어그램 유형 선언이 첫 줄에 있는가 (`flowchart TB`, `sequenceDiagram`)
- [ ] 모든 `subgraph`가 `end`로 닫혔는가
- [ ] 모든 `alt`/`loop`/`rect` 블록이 `end`로 닫혔는가

### 노드 ID
- [ ] 노드 ID에 공백, 하이픈, 특수문자가 없는가
- [ ] 노드 ID가 Mermaid 예약어(`end`, `subgraph`, `click`, `style`, `class`, `default`)가 아닌가
- [ ] 같은 ID가 다른 의미로 중복 사용되지 않았는가

### 엣지 & 라벨
- [ ] 엣지 라벨이 큰따옴표로 감싸져 있는가
- [ ] 라벨 안에 큰따옴표가 포함되지 않았는가
- [ ] 화살표 문법이 올바른가 (`-->`, `---`, `-.-`, `-.->`, `==>`)
- [ ] 참조하는 노드 ID가 실제로 정의되어 있는가

### Sequence 전용
- [ ] `participant` 선언이 다이어그램 상단에 있는가
- [ ] 메시지 문법이 올바른가 (`->>`, `-->>`, `->`, `-->`)
- [ ] `Note over` 구문에서 participant 이름이 정확한가

### 특수 문자
- [ ] 라벨에 `()`, `[]`, `{}`, `<>` 같은 괄호가 있으면 따옴표로 감쌌는가
- [ ] 콜론(`:`)이 포함된 텍스트는 따옴표로 감쌌는가
- [ ] 앰퍼샌드(`&`), 파이프(`|`) 등 특수 문자를 사용하지 않았는가 (HTML entity 필요)

---

## 흔한 에러와 해결

| 에러 상황 | 원인 | 해결 |
|-----------|------|------|
| `Parse error` on label | 라벨에 특수문자 (`:`, `()`) | 큰따옴표로 감싸기 |
| `Unknown diagram type` | `graph` 사용 | `flowchart`로 변경 |
| `Expecting 'end'` | subgraph 미닫힘 | `end` 추가 |
| 노드가 표시 안 됨 | ID가 예약어 | ID 변경 (예: `end` → `END_NODE`) |
| 화살표가 안 그려짐 | 잘못된 화살표 문법 | `-->`, `-.->`등 정확한 문법 사용 |
| `Duplicate node` | 같은 ID 다른 라벨 | ID 통일 또는 분리 |
| subgraph 안 노드 참조 실패 | subgraph 밖에서 미정의 노드 참조 | 노드를 subgraph 안에 먼저 정의 |

---

## 출력 규칙

- 파일 확장자: `.mmd`
- 파일 하나에 다이어그램 하나
- 파일명은 내용을 반영: `auth-flow.mmd`, `k8s-architecture.mmd`
- 저장 경로: `docs/diagrams/` 에 저장 (없으면 `mkdir -p`로 생성)
- Markdown 코드 펜스 (````mermaid`) 없이 순수 Mermaid 문법만 저장
- 변환 안내 메시지를 반드시 포함
