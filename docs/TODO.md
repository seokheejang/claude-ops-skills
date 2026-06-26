# TODO — Skill Ideas

아직 착수 안 한 스킬 아이디어의 의도·제약·수집할 자료 상세 메모.
착수 시 `/write-a-skill`로 들어가고, 완료되면 이 항목을 `archive/NN-*.md` 작업 문서로 옮긴다.

> 전체 작업 백로그(완료 이력 포함)는 [CHANGELOG.md](CHANGELOG.md) "다음 작업 후보" 참조.
> 이 파일은 그중 **스킬 신규 작성 아이디어**의 상세 메모만 담는다.

> 세 아이디어의 공통 패턴: **(1) 규격/표준은 존재하나 방식이 다양하고 상황별로 크게 달라짐**,
> **(2) 좋은 샘플 코드 수집이 선행되어야 함**, **(3) 가이드라인부터 잡아가며 내 경험을 녹임**.
> → 셋 다 "정적 지식 + 큐레이션" 성격이라 [learnings/claude-code.md](learnings/claude-code.md)의
> 결정 트리상 **직접 작성(write-a-skill)** 이 맞다. 단 샘플 수집 비중이 커서 references/ 가 두꺼워질 것.

---

## 1. helm-values (Helm values/templates 작성 가이드)

**목표**: 표준을 지키면서 협업·재사용성·확장성이 좋은 Helm을 짤 수 있게 돕는 스킬. values와 templates 선언 방식을
적재적소에 알맞게 고를 수 있도록 가이드.

**문제 인식 (사용자 원문 취지)**
- values/templates 선언 방식이 너무 다양하고 때론 복잡하며, 서비스마다 여러 방향으로 달라짐
- 그럼에도 표준을 지키면서 최대한 협업 가능하고 재사용·확장 가능한 case를 만들고 싶음
- 스킬과 함께 가이드라인을 잡아가는 형태 (정답 박제가 아니라 점진적 정립)

**수집할 자료 (선행)**
- 좋은 Helm chart 샘플 코드 다수 (공식 차트, bitnami, 잘 만든 OSS 차트의 values 구조)
- values 계층화 패턴 (global, per-env overlay, `values-prod.yaml` 분리 등)
- templates 재사용 패턴 (`_helpers.tpl`, named templates, library charts)
- anti-pattern 모음 (과도한 중첩, 마법값, 조건 분기 폭발 등)

**내가 녹일 경험**: 그간 Helm 다루며 느낀 점 (착수 시 인터뷰로 추출 — grill-me 활용 가능)

**열린 질문 / 결정 필요**
- helm-ops(이미 chart authoring 가이드 references/helm-charts.md 보유)와 관계 → 흡수? 별도 스킬? **중복 점검 필수**
- "가이드 제시"인가 "values 생성"인가 — 추론 자유도(가드레일형 vs 절차 고정형) 합의 필요
- 표준 출처 명시 (Helm 공식 best practices 문서 우선 — DevOps 리서치 원칙)

## 2. grafana-dashboard (Grafana dashboard JSON 작성 가이드)

**목표**: 규격화된 Grafana dashboard JSON을 기반으로 DevOps에 필요한 대시보드를 짜는 스킬.
가이드라인부터 시작해 잡아감.

**문제 인식 (사용자 원문 취지)**
- Grafana도 규격화된 JSON 형식이 존재 → 그것을 기반으로 작성
- 상황에 따라 많이 달라짐 (수집 메트릭, 소스에 따라)

**제시되어야 할 것**
- Prometheus 스택 기반 패턴
- ServiceMonitor / PodMonitor (메트릭 수집 경로)
- 그 외 메트릭 수집 방법들

**수집할 자료 (선행)**
- 좋은 dashboard JSON 샘플 + 방법론 (grafana.com/dashboards 인기 대시보드, kube-prometheus-stack 기본 대시보드)
- panel/target/templating(variables) JSON 구조 표준
- PromQL 쿼리 패턴 (rate, histogram_quantile, recording rule 등)
- datasource 변수화, row/panel 레이아웃 컨벤션

**열린 질문 / 결정 필요**
- JSON 직접 생성 스킬인가, 가이드+검증 스킬인가
- promql-generator(기존 Backlog 후보)와 관계 — PromQL 부분 공유?
- Grafana 스키마 버전 종속성 (시점 종속 정보 회피 — write-a-skill 체크리스트)

## 3. html-doc (MD → 보기 좋은 HTML + 다이어그램 가이드)

**목표**: md 문서를 사람에게 공유·이해시키기 위한 HTML을 일관되게 잘 뽑는 스킬.
다이어그램을 AI가 제멋대로 그리는 문제를 가이드화해서 최적화.

**문제 인식 (사용자 원문 취지)**
- 요즘 md를 사람에게 공유·이해시키는 데 HTML을 자주 씀
- 매번 HTML 요청 + 다이어그램 그리면 AI가 제멋대로 그리기 일쑤
- 최근 경험: "아키텍쳐?" 방식으로 mermaid를 SVG화하고 그것을 다듬어 더 보기 좋은 형식으로 진화시키는 흐름

**수집할 자료 (선행)**
- 최신 HTML 문서화 샘플 (보기 좋은 레이아웃, 타이포, 코드블록 스타일)
- mermaid → SVG 변환 + 후처리(다듬기) 워크플로우 ("아키텍쳐?" 방식 정체 확인 필요 — Excalidraw? 특정 도구?)
- 자체 Artifact 도구(claude.ai HTML 렌더)와의 연계 가능성 검토
- 기존 `_disabled/mmdraw`(mermaid 검증/렌더 scripts/render.sh)에서 재활용할 부분

**열린 질문 / 결정 필요**
- "아키텍쳐?" 방식이 정확히 무엇인지 사용자에게 확인 (도구명/워크플로우)
- mmdraw를 되살려 합치나, 신규로 가나 ([_disabled/mmdraw] 부활 vs html-doc 신규)
- 다이어그램 "제멋대로" 방지 = 결정론적 scripts/ 로 뺄 영역 (렌더링·검증)
- Artifact(self-contained HTML, CSP 제약)와 정합성
