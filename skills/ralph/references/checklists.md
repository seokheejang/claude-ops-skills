# ralph — Domain Checklists

작업 도메인별 검증 체크리스트. ralph Phase 2에서 작업 내용에 따라 적절한 섹션 로드.

## 도메인 감지

작업 설명/대상 파일을 보고 아래 중 가장 가까운 도메인을 선택. 복수 해당 시 모두 적용.

| 신호 | 도메인 |
|------|--------|
| `.go`, `.ts`, `.py`, `.rs`, `.js` 등 코드 파일 / "함수", "구현", "리팩토링" | 코드 작성/수정 |
| `kubectl`, `helm`, `terraform`, `argocd`, `Chart.yaml`, `*.tf`, manifest, RBAC | DevOps/IaC |
| `*.md`, `settings.json`, config 파일, "문서", "정리" | 설정/문서 |
| 위 어디에도 안 맞을 때 | 범용 |

## 코드 작성/수정

- [ ] 문법 에러 없음 (lint/build 통과)
- [ ] 보안 취약점 없음 (injection, hardcoded secrets, XSS)
- [ ] 엣지 케이스 처리됨
- [ ] 기존 코드와 일관된 스타일
- [ ] 불필요한 코드 없음 (over-engineering 방지)

## DevOps/IaC (K8s, Helm, Terraform, ArgoCD)

- [ ] READ-ONLY 안전 규칙 준수 (mutating 명령어 없음)
- [ ] settings.json deny 규칙과 SKILL.md 금지 목록 일치
- [ ] 하드코딩된 시크릿/경로/IP 없음
- [ ] 권한이 최소 범위로 제한됨 (RBAC, IAM)
- [ ] 예시 값이 제네릭명 사용 (`my-cluster`, `my-app`, `<DB_PASSWORD>` 등)
- [ ] 커밋 대상이면 CLAUDE.md 보안 체크리스트 7항목도 검증
  - 로컬 경로 / 인프라명 / kubeconfig 파일명 / 예시 일반화 / IP·호스트 / credentials / .gitignore

## 설정/문서

- [ ] 다른 파일과 일관성 유지 (네이밍, 컨벤션, 참조 경로)
- [ ] 누락 항목 없음
- [ ] 오타/포맷 오류 없음
- [ ] 마크다운 테이블/링크 정상 (depth, anchor 유효)

## 범용 (위에 해당 없을 때)

- [ ] 사용자 요구사항 완전히 충족
- [ ] 결과물이 정확하고 완성됨
- [ ] 불필요한 부작용 없음
