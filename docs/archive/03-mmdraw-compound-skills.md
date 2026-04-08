# mmdraw + compound 스킬 추가

**날짜**: 2026-04-08
**상태**: 완료

## 배경

Claude Code에서 다이어그램 생성과 작업 종합(Compound Engineering) 기능이 필요했다.
초기에는 Excalidraw JSON을 직접 생성하는 `draw` 스킬로 시작했으나, 좌표 수동 계산의 한계로
Mermaid 기반 `mmdraw`로 전환. 작업 종합은 Every Inc의 Compound Engineering 개념을 적용.

## 변경 내용

### mmdraw 스킬

소스/문서 분석 후 문법 에러 없는 Mermaid 다이어그램을 생성하는 스킬.
Excalidraw 변환은 https://mermaid-to-excalidraw.vercel.app/ 에서 수동 수행.

| 파일/디렉토리 | 변경 | 설명 |
|---------------|------|------|
| `skills/mmdraw/SKILL.md` | 신규 | Mermaid 문법 규칙 + 검증 체크리스트 포함 |
| `docs/diagrams/install-flow.mmd` | 신규 | install.sh 플로우차트 (테스트용) |

### compound 스킬

작업 완료/중단 시 문서 정리, 학습 축적, CHANGELOG 업데이트를 수행하는 스킬.
Compound Engineering(Every Inc, 2025)의 핵심 개념 적용.

| 파일/디렉토리 | 변경 | 설명 |
|---------------|------|------|
| `skills/compound/SKILL.md` | 신규 | 4단계 워크플로우 (Scan → 분류 → 작성 → 정리) |
| `docs/archive/` | 신규 | 완료된 작업 문서 보관 디렉토리 |
| `docs/learnings/` | 신규 | 학습 기록 축적 디렉토리 |
| `docs/diagrams/` | 신규 | Mermaid 다이어그램 디렉토리 |

### draw 스킬 시도 및 폐기

coleam00/excalidraw-diagram-skill을 참고하여 Excalidraw JSON을 직접 생성하는 스킬을 시도.
roughness, fontFamily, 곡선 화살표 등 여러 차례 개선을 시도했으나 결과물 품질이 부족하여 폐기.
이후 `@excalidraw/mermaid-to-excalidraw` npm 패키지를 Node.js에서 활용하려 했으나
DOM 의존성(jsdom SVG 한계, Playwright CDN 로딩 실패)으로 단념.

### 기타 변경

| 파일 | 변경 | 설명 |
|------|------|------|
| `.gitignore` | 수정 | mmdraw 아티팩트 제외 패턴 추가 |
| `README.md` | 수정 | Skills 테이블에 mmdraw, compound 추가. Structure 트리 업데이트. Reference에 coleam00 레포 추가 |

## 결과

- `mmdraw`: install.sh 플로우차트로 테스트 완료. Mermaid 문법 에러 없이 생성 확인.
- `compound`: 이 문서 자체가 compound 스킬의 첫 실행 결과.
- `draw` (폐기): Excalidraw JSON 직접 생성은 레이아웃 품질 한계. Mermaid → Excalidraw 웹 변환이 훨씬 우수.

→ CHANGELOG.md에 기록됨
