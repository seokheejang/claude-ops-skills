# claude-ops-skills

Claude Code Skills & Agents for DevOps workflows.
K8s 트러블슈팅, 블록체인 RPC 모니터링, DB 조회, SSH 인스펙션 등을 재사용 가능한 skill로 관리.

## Quick Start

```bash
# 설치 (심링크 + settings 머지 + CLAUDE.md 머지)
./scripts/install.sh

# 업데이트 (git pull + 재설치)
./scripts/update.sh

# 제거
./scripts/uninstall.sh
```

## Skills

| Skill | 명령어 | 설명 |
|-------|--------|------|
| k8s-ops | `/k8s-ops <cluster>` | K8s 클러스터 조회 (get, describe, logs, top) |
| k8s-security | `/k8s-security <cluster>` | K8s 보안 점검 (RBAC, NetworkPolicy, Pod Security 감사) |
| ssh-ops | `/ssh-ops <host>` | SSH 서버 인스펙션 |
| rpc-health | `/rpc-health <endpoint>` | 블록체인 RPC 노드 헬스체크 |
| db-ops | `/db-ops <database>` | DB 조회 (SELECT, SHOW만 허용) |

## Agents

| Agent | 설명 |
|-------|------|
| k8s-debugger | K8s 이슈 체계적 디버깅 |
| k8s-security-auditor | K8s 종합 보안 감사 (위험도 분석 + 개선 가이드) |
| rpc-monitor | RPC 노드 상태 모니터링 |

## Cluster Aliases

`clusters.yaml`에 `aliases` 필드를 추가하면 짧은 이름으로 클러스터를 지정할 수 있습니다:

```yaml
# skills/k8s-ops/clusters.yaml (로컬 전용, .gitignore)
clusters:
  my-cluster:
    kubeconfig: "~/.kube/my_cluster_config"
    aliases: ["dev", "my dev"]     # /k8s-ops dev → my-cluster
  my-prod:
    kubeconfig: "~/.kube/my_prod_config"
    aliases: ["prod"]              # /k8s-security prod → my-prod
```

사용 예시:
- `/k8s-ops dev` → aliases에서 `dev` 매칭 → `my-cluster`
- `/k8s-security prod` → aliases에서 `prod` 매칭 → `my-prod`
- `/k8s-ops my-cluster` → 키 이름 정확히 일치 → `my-cluster`

매칭 우선순위: 키 이름 정확히 일치 > aliases 일치 > 부분 매칭 (후보 복수면 선택 요청)

> `clusters.yaml`은 `.gitignore`에 포함되어 있어 실제 클러스터명이 public repo에 노출되지 않습니다. 설정 예시는 `clusters.yaml.example`을 참고하세요.

## Structure

```
├── skills/           # ~/.claude/skills/에 심링크
│   ├── k8s-ops/      # K8s 조회 skill + clusters.yaml (로컬 자동 생성)
│   ├── k8s-security/ # K8s 보안 점검 skill
│   ├── ssh-ops/      # SSH 인스펙션 skill
│   ├── rpc-health/   # RPC 헬스체크 skill
│   └── db-ops/       # DB 조회 skill
├── agents/           # 서브에이전트 정의
├── configs/          # 설정 템플릿
│   ├── settings.json.template     # allow/deny 규칙
│   ├── claude.md.template         # CLAUDE.md 머지 내용
│   └── settings.local.json.example
├── scripts/          # 설치/관리
│   ├── install.sh    # 백업 → 심링크 → 머지
│   ├── uninstall.sh
│   └── update.sh
└── templates/        # 새 skill/agent 생성 템플릿
```

## Install Script 동작

1. **백업**: 기존 파일을 `~/.claude/backups/claude-ops-skills/{timestamp}/`에 저장
2. **Skills 심링크**: `skills/*` → `~/.claude/skills/*` (이미 심링크면 스킵)
3. **settings.json 머지**: allow/deny 규칙을 기존에 추가 (hooks 등 보존, 중복 제거)
4. **CLAUDE.md 머지**: 마커(`# === claude-ops-skills:start/end ===`) 기반 블록 관리
5. **settings.local.json**: 절대 수정하지 않음

## Safety

- 모든 K8s 작업은 **READ-ONLY** (get, describe, logs, top, exec 조회)
- kubectl 변경 명령어(apply, delete, patch 등)는 deny 규칙 + CLAUDE.md 지침으로 이중 차단
- 보안 정보(kubeconfig 내용, SSH 키)는 이 repo에 포함되지 않음
- `clusters.yaml`은 로컬 전용 — `install.sh`가 `~/.kube/` 스캔하여 자동 생성 (`.gitignore`에 포함)


## Reference

- [cc-devops-skills](https://github.com/akin-ozer/cc-devops-skills) - DevOps skill 구조 및 SKILL.md 패턴 참고
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code plugin/agent 아키텍처 참고
- [claude-code-auto-approve](https://github.com/oryband/claude-code-auto-approve) - PreToolUse hook 복합 명령 파싱 (shfmt AST) 참고