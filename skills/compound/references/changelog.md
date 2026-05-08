# compound — CHANGELOG Reference

`docs/CHANGELOG.md` 갱신 규칙. compound 워크플로 3단계 (C).

## 갱신 시점

**`completed` 상태일 때만** 새 버전 항목을 추가한다. `paused`는 갱신하지 않음.

## 항목 템플릿

```markdown
### vX.Y -- <Title> (YYYY-MM-DD)

- [0N-<name>.md](archive/0N-<name>.md) 작업 문서
- <변경 요약 bullet point>
- <변경 요약 bullet point>
```

### 필수 요소

- 버전 번호 (vX.Y)
- 한 줄 제목 (작업의 핵심)
- 날짜 (YYYY-MM-DD)
- 작업 문서 링크 (archive 경로)
- 변경 요약 bullet 2~5개

## 버전 번호 규칙

기존 최신 버전에서 minor +1.

| 기존 | 다음 |
|------|------|
| v0.5 | v0.6 |
| v0.9 | v0.10 |
| v1.2 | v1.3 |

major bump (v0.x → v1.0)는 사용자 결정 필요. 자동 적용하지 않는다.

## 작성 원칙

- **append-only**: 기존 항목 절대 수정/삭제 금지
- **archive 링크 우선**: 문서 이동 전 CHANGELOG 링크를 먼저 업데이트
- **사용자 친화적 요약**: 파일 경로/내부 구조보다 *무엇이 가능해졌는지*를 bullet으로
