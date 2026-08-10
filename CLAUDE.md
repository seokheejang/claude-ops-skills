# claude-ops-skills

DevOps 운영용 Claude Code Skills & Agents 저장소.

## Repository Structure

- `skills/` - Claude Code skills (`~/.claude/skills/`에 심링크로 설치)
- `agents/` - 복합 워크플로우용 에이전트 정의
- `configs/` - 사용자 설정 템플릿
- `scripts/` - 설치/관리 스크립트
- `templates/` - 새 skill/agent 생성용 템플릿

## 대화 원칙

- 확실한 건 명확히 동의하고, 불확실하거나 틀린 부분은 동조 대신 근거와 함께 짚을 것
- 수치나 근거 없이 과장하지 말 것. 영향이 미미하면 미미하다고 말할 것
- 불확실하면 "모르겠다" 또는 "확인 필요"라고 말할 것

## DevOps 리서치 원칙

신규 도구/애드온 도입 검토, 아키텍처 개선 논의, 비정형 장애에는 `best-practice` 스킬 사용
(공식 문서 우선 · 업계 사례 비교 · 대안 비교 · 출처 검증 절차 포함).
단순 조회, 설정 변경, 코드 수정 등 일상 작업에는 적용하지 않는다.

## Compaction 지시

compact 시 반드시 보존할 것: 대상 컨텍스트/호스트명, 사용자가 붙여넣은 실측 출력, 발견된 이슈 목록, 수정한 파일 목록.

## Rules

- 모든 K8s 작업은 READ-ONLY (get, describe, logs, top, exec 조회만 허용)
- 절대 secrets, kubeconfig 파일, .env 파일을 커밋하지 않을 것
- 인프라 스킬은 **직접 실행이 아니라 복붙 가능한 READ-ONLY 명령 묶음 출력**이 기본 (clusters.yaml 자동 생성은 2026-08-10 비활성화)
- Skill 디렉토리명이 곧 slash command명 (예: `k8s-ops` → `/k8s-ops`)

## Skill Naming Convention

- kebab-case 사용 (예: `k8s-ops`, `k8s-craft`)
- 각 skill 디렉토리에 반드시 SKILL.md 포함

## Commit Message Convention

Conventional Commits 사용:
- `feat:` 새 기능 / `fix:` 버그 수정 / `docs:` 문서 / `chore:` 설정·빌드 / `ci:` CI/CD / `refactor:` 리팩토링 / `test:` 테스트
- scope 선택 사용: `feat(k8s-security): add RBAC audit`
- **커밋 메시지는 반드시 영어로 작성**

## Commit / PR 시 보안 체크리스트 (CRITICAL)

자동 검증은 `scripts/pre-commit.sh`(git pre-commit 훅)가 담당 — 로컬 경로, 내부 인프라명,
kubeconfig 파일명, 공인 IP, credentials, 민감 파일. **`--no-verify`로 우회하지 말 것.**

훅이 못 잡는 것만 수동 확인:
- **예시 파일 일반화**: example/template 파일에는 `my-cluster`, `my-prod` 등 제네릭 이름만 사용
- **.gitignore 상태**: `.env`, `settings.local.json`, `db-targets.yaml` 등이 여전히 제외 상태인지 확인

## Learnings

작업 중 발견한 패턴, 해결법, 의사결정 근거는 `docs/learnings/`에 축적됨.
새 작업 시작 전 관련 학습 기록이 있는지 확인하면 삽질을 줄일 수 있음.
