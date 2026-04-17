# Skill Hardening: ssh-ops, db-ops, rpc-agent

**날짜**: 2026-04-17
**상태**: 완료

## 배경

Opus 4.7 업그레이드 이후 "성능이 어디까지 올라갔나" 확인 겸 프로젝트 전반을 감사. 무의미한 리팩토링을 배제하고, 사용자 경험이나 신뢰성에 실질적으로 영향 주는 포인트만 강화하는 것이 원칙.

Explore agent로 14개 skill 전수 감사 결과, 아래 3건이 **진짜 문제**로 드러났다:

1. **rpc-agent**: 4개 모듈 중 `block-tx-count`만 구현, 나머지 3개는 "TODO" 상태로 선언만 되어있어 사용자가 호출 시 동작하지 않음
2. **db-ops**: `/db-ops <이름>`에서 MySQL/PostgreSQL 중 어떤 엔진으로 붙을지 결정 로직 부재, 접속 정보 관리 체계 없음
3. **ssh-ops**: 첫 접속 시 호스트 키 확인 prompt 대응 정책 없음 — 자동화 흐름에서 대화형 prompt로 행 걸릴 위험

low priority로 분류한 항목(워크플로우 다이어그램, learnings 마이그레이션 스크립트, cluster 해상도 통합 등)은 의도적으로 제외 — 과잉 추상화 방지.

## 변경 내용

| 파일/디렉토리 | 변경 | 설명 |
|---|---|---|
| `skills/ssh-ops/SKILL.md` | 수정 | SSH 연결 정책 섹션 추가 (BatchMode=yes, ConnectTimeout=10, StrictHostKeyChecking=accept-new, ServerAliveInterval=30), 표준 호출 패턴 및 에러 분기 |
| `skills/db-ops/SKILL.md` | 수정 | Target Resolution 섹션 (`${CLAUDE_SKILL_DIR}/db-targets.yaml` 참조), 연결 패턴 (MySQL `MYSQL_PWD`, PG `PGPASSWORD` 환경변수 방식), Troubleshooting 확장 |
| `skills/db-ops/db-targets.yaml.example` | 신규 | engine / host / port / user / database / **password_env** / aliases / sslmode 스키마. 비밀번호는 환경변수 이름만 저장 (값 아님) |
| `.gitignore` | 수정 | `skills/db-ops/db-targets.yaml` 추가 |
| `.github/workflows/security-check.yml` | 수정 | FORBIDDEN_FILES 목록에 `skills/db-ops/db-targets.yaml` 추가 |
| `agents/rpc-analytics.md` | 수정 | `gas-analysis` 모듈 스펙 (EVM 전용: gasUsed/utilization/baseFeePerGas), `block-time-analysis` 모듈 스펙 (EVM+Cosmos: interval/stddev/outlier), `address-activity`는 명시적 scope-out (인덱서 권장) |
| `skills/rpc-agent/SKILL.md` | 수정 | Available Modules 표 업데이트 (상태 "TODO" → "사용 가능", 지원 체인 열 추가), 사용 예시 확장 |
| `scripts/pre-commit.sh`, `.github/workflows/security-check.yml` | 수정 | credential 검사 시 bash 변수 참조(`$VAR`, `${VAR}`, `${!VAR}`)를 false positive로 제외. db-ops의 `PGPASSWORD="${!PASSWORD_ENV}"` 예시에서 오탐 발생 → 커밋 과정에서 발견하여 fix |

## 결과

- **ssh-ops**: 자동화 호출 시 prompt/hang/MITM 가능성 제거. 호스트 키 변경 감지되면 사용자 확인 요청으로 분기
- **db-ops**: K8s의 clusters.yaml과 동일 UX로 통일. 보안 방어는 3중(파일 내 `password_env`만 저장 + `.gitignore` + CI forbidden list). 비밀번호 실수 커밋 위험 차단
- **rpc-agent**: 사용 가능 모듈이 1개 → 3개로 확장. `address-activity`는 인덱서 권장으로 명시적 scope-out하여 "TODO 방치" 상태 제거
- diff 스케일: 6개 파일 수정 + 1개 신규, +125/-14 lines. 개인 경로·인프라명·공인 IP·실제 credentials 노출 없음 확인

### end-to-end 검증 메모

- `/db-ops` 호출해보려 했으나 Claude Code CLI가 SKILL.md를 **세션 시작 시 캐시**해서 수정 내용이 현재 세션에 반영 안 됨 (learnings/claude-code.md 참조)
- 심링크·파일 최신 상태는 확인됨
- 실제 DB 연결 테스트는 사용자가 재시작 후 `db-targets.yaml` 작성하여 수행 예정

## 핸드오프

→ CHANGELOG v0.8 참조. 다음 세션 테스트 항목:
- Claude Code 재시작 후 `/db-ops` 호출 → 최신 SKILL.md 로드 확인 + Target Resolution 동작 확인
- 실제 MySQL/PG 접속 테스트 (사용자가 `db-targets.yaml` 작성 후)
- `/rpc-agent <endpoint> gas-analysis --last 100` 실행 테스트
