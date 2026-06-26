# mmdraw — Mermaid 문법 레퍼런스

SKILL.md 본문에서 분리한 상세 문법 규칙. 다이어그램 작성 중 참조용.

## Flowchart

### 선언

```
flowchart TB    ← 위→아래 (아키텍처, 계층 구조)
flowchart LR    ← 왼→오른 (파이프라인, 시간 흐름)
```

`graph`가 아닌 **`flowchart`** 사용. `graph`는 일부 기능 미지원.

### 노드

| 형태 | 문법 | 용도 |
|------|------|------|
| 사각형 | `ID["Label"]` | 기본 컴포넌트 |
| 원통형 | `ID[("Label")]` | 데이터베이스, PVC, 스토리지 |
| 육각형 | `ID{{"Label"}}` | Secret, ConfigMap |
| 원형 | `ID(("Label"))` | 외부 액터, 시작/끝점 |
| 다이아몬드 | `ID{"Label"}` | 조건 분기 |
| 둥근 사각형 | `ID("Label")` | 프로세스, 서비스 |

**노드 ID 규칙**:
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

**라벨 규칙**:
- 라벨은 반드시 큰따옴표: `-- "label" -->` ✅
- 따옴표 없으면 파싱 에러 위험: `-- label -->` ❌
- 라벨 안에 큰따옴표 금지. 작은따옴표로 대체: `-- "Engine API '8551'" -->` ✅
- 콜론 포함 시 반드시 따옴표: `-- "port :8545" -->` ✅

### Subgraph

```mermaid
subgraph ID["Display Name"]
    %% 내용
end
```

**규칙**:
- ID와 표시명 분리: `subgraph EL["Execution Layer"]` ✅
- ID에 공백/특수문자 금지: `subgraph "Execution Layer"` ❌
- 반드시 `end`로 닫음
- 중첩 가능 (subgraph 안에 subgraph)
- subgraph 밖에서 안의 노드 참조 가능

---

## Sequence

### 선언

```
sequenceDiagram
```

### Participant

```
participant ID as Display Name
```

- `participant`를 먼저 선언하면 순서 보장
- 미선언 시 등장 순서대로 배치

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

## 흔한 에러와 해결

| 에러 상황 | 원인 | 해결 |
|-----------|------|------|
| `Parse error` on label | 라벨에 특수문자 (`:`, `()`) | 큰따옴표로 감싸기 |
| `Unknown diagram type` | `graph` 사용 | `flowchart`로 변경 |
| `Expecting 'end'` | subgraph 미닫힘 | `end` 추가 |
| 노드가 표시 안 됨 | ID가 예약어 | ID 변경 (예: `end` → `END_NODE`) |
| 화살표가 안 그려짐 | 잘못된 화살표 문법 | `-->`, `-.->` 등 정확한 문법 |
| `Duplicate node` | 같은 ID 다른 라벨 | ID 통일 또는 분리 |
| subgraph 안 노드 참조 실패 | subgraph 밖에서 미정의 노드 참조 | 노드를 subgraph 안에 먼저 정의 |
