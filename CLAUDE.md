# claude-ops-skills

DevOps 운영용 Claude Code Skills & Agents 저장소.

## Repository Structure

- `skills/` - Claude Code skills (`~/.claude/skills/`에 심링크로 설치)
- `agents/` - 복합 워크플로우용 에이전트 정의
- `configs/` - 사용자 설정 템플릿
- `scripts/` - 설치/관리 스크립트
- `templates/` - 새 skill/agent 생성용 템플릿

## Rules

- 모든 K8s 작업은 READ-ONLY (get, describe, logs, top, exec 조회만 허용)
- 절대 secrets, kubeconfig 파일, .env 파일을 커밋하지 않을 것
- clusters.yaml은 로컬 전용 (install.sh가 자동 생성, .gitignore에 포함)
- Skill 디렉토리명이 곧 slash command명 (예: `k8s-ops` → `/k8s-ops`)

## Skill Naming Convention

- kebab-case 사용 (예: `k8s-ops`, `rpc-health`)
- 각 skill 디렉토리에 반드시 SKILL.md 포함

## Commit Message Convention

Conventional Commits 사용:
- `feat:` 새 기능 / `fix:` 버그 수정 / `docs:` 문서 / `chore:` 설정·빌드 / `ci:` CI/CD / `refactor:` 리팩토링 / `test:` 테스트
- scope 선택 사용: `feat(k8s-security): add RBAC audit`

## Commit / PR 시 보안 체크리스트 (CRITICAL)

커밋 또는 주요 변경 전 반드시 아래 항목을 확인할 것:

1. **로컬 경로 노출 금지**: `~/dev/<username>/`, `/Users/<username>/` 등 개인 경로가 포함되지 않았는지 확인
2. **내부 인프라명 노출 금지**: 실제 클러스터명, 서비스명, 회사/프로젝트 고유 이름이 코드나 문서에 포함되지 않았는지 확인
3. **kubeconfig 파일명 노출 금지**: `~/.kube/` 아래 실제 config 파일명은 clusters.yaml(gitignore됨)에만 존재해야 함
4. **예시 파일은 일반화**: example/template 파일에는 `my-cluster`, `my-prod` 등 제네릭 이름만 사용
5. **IP/호스트/URL 확인**: 실제 서버 IP, 내부 도메인, 엔드포인트가 하드코딩되지 않았는지 확인
6. **credentials 확인**: password, token, secret, API key 등이 포함되지 않았는지 확인
7. **.gitignore 확인**: `clusters.yaml`, `.env`, `settings.local.json` 등이 여전히 제외 상태인지 확인
