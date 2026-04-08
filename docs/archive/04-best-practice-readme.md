# best-practice Skill 추가 + README 개선

**날짜**: 2026-04-08
**상태**: 완료

## 배경

DevOps 의사결정 시 업계 best practice를 매번 수동으로 설명해야 하는 반복 작업을 스킬로 자동화.
README.md도 업계 표준 대비 개선 여지가 있어 함께 정비.

## 변경 내용

| 파일/디렉토리 | 변경 | 설명 |
|---------------|------|------|
| `skills/best-practice/SKILL.md` | 신규 | DevOps best practice 리서치 스킬 (5단계 워크플로우, 다층 소스 리서치, 구조화된 출력) |
| `README.md` | 수정 | Description 확장 (대상 사용자 명시), ToC 추가, Prerequisites 테이블 추가, Quick Start에 clone+첫실행 예시, 세부 섹션 접이식(`<details>`) 처리, Skills/Structure에 best-practice 항목 추가 |

## 결과

- `/best-practice <topic>` 명령어로 업계 사례, 커뮤니티 지혜, 공식 문서를 체계적으로 조사 가능
- README가 업계 표준 구조(Description+ToC+Prerequisites+Quick Start 확장+접이식)로 개선됨
- `make install` 실행하여 심링크 생성 확인 완료

## 핸드오프

→ CHANGELOG.md에 기록됨
