---
title: Excalidraw 다이어그램 생성 방식 비교
date: 2026-04-08
category: tooling
related: skills/mmdraw, coleam00/excalidraw-diagram-skill
---

## 컨텍스트

Claude Code에서 Excalidraw 다이어그램을 프로그래밍 방식으로 생성하려고 3가지 접근을 시도했다.

## 내용

### 1. Excalidraw JSON 직접 생성 (실패)

coleam00/excalidraw-diagram-skill 방식. Claude가 좌표(x, y), 크기(width, height),
바인딩(boundElements) 등을 직접 계산하여 `.excalidraw` JSON을 생성한다.

**한계:**
- 화살표가 polyline(직선 연결)만 가능. 베지어 곡선 불가 → 화살표가 부자연스러움
- 좌표를 수동 계산하니 레이아웃이 기계적. 사람이 그린 것과 차이가 큼
- `roughness: 1` + `fontFamily: 1`로 손그림 느낌을 줘도 레이아웃 자체가 딱딱함
- 렌더→확인→수정 루프를 돌아도 품질 개선에 한계

### 2. @excalidraw/mermaid-to-excalidraw npm 패키지 (부분 실패)

Excalidraw 공식 팀의 변환 라이브러리. Mermaid → Excalidraw JSON.

**한계:**
- 브라우저 DOM 필수 (`document.createElement`, `getBBox`, `getComputedTextLength`)
- jsdom으로 대체 시 SVG 메서드 미지원 → subgraph 파싱 실패 (`getBBox is not a function`)
- Playwright headless 브라우저로 우회 시도 → esm.sh CDN 로딩 실패 (404, 타임아웃)
- 로컬 HTTP 서버 + Playwright 조합도 번들 호환성 문제로 실패

### 3. Mermaid 텍스트 생성 + 웹 변환 (성공)

Claude가 Mermaid 문법만 생성하고, https://mermaid-to-excalidraw.vercel.app/ 에서 수동 변환.

**장점:**
- Claude는 Mermaid 문법 생성에 능숙 (텍스트 기반, 레이아웃 계산 불필요)
- 변환 사이트가 dagre 레이아웃 엔진으로 자동 배치 → 결과물이 깔끔
- 곡선 화살표, 서브그래프, 손그림 스타일 모두 지원

## 왜 중요한가

다이어그램 생성 스킬을 만들 때, "AI가 좌표를 직접 계산"하는 접근은 피해야 한다.
레이아웃 엔진(dagre, elk 등)에 맡기는 텍스트 기반 접근이 훨씬 효과적이다.
Mermaid는 Claude가 잘 생성할 수 있고, 변환은 검증된 도구에 위임하는 것이 현실적이다.
