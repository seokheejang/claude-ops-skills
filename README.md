# claude-ops-skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skills%20%26%20Agents-blueviolet)](https://github.com/anthropics/claude-code)

Claude Code Skills & Agents for DevOps workflows.
Reusable skills for K8s troubleshooting, Helm/Terraform IaC authoring, ArgoCD GitOps monitoring, blockchain RPC monitoring, DB inspection, and SSH server checks.

## Quick Start

```bash
make install    # Install (symlinks + settings merge + CLAUDE.md merge)
make update     # Update (git pull + reinstall)
make uninstall  # Uninstall
make test       # Run PreToolUse hook tests
```

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| k8s-ops | `/k8s-ops <cluster>` | K8s cluster inspection (get, describe, logs, top) |
| k8s-security | `/k8s-security <cluster>` | K8s security audit (RBAC, NetworkPolicy, Pod Security) |
| ssh-ops | `/ssh-ops <host>` | SSH server inspection |
| rpc-health | `/rpc-health <endpoint>` | Blockchain RPC node health check |
| rpc-agent | `/rpc-agent <endpoint> <module>` | RPC analytics agent (block traversal, tx counting) |
| db-ops | `/db-ops <database>` | DB read-only queries (SELECT, SHOW only) |
| helm-ops | `/helm-ops <cluster-or-chart>` | Helm chart validation, release inspection, chart authoring guide |
| terraform-ops | `/terraform-ops <directory>` | Terraform state inspection, plan analysis, IaC authoring guide |
| argocd-ops | `/argocd-ops <app-or-context>` | ArgoCD app status, sync monitoring, drift detection, GitOps manifest authoring |

## Agents

| Agent | Description |
|-------|-------------|
| k8s-debugger | Systematic K8s issue debugging |
| k8s-security-auditor | Comprehensive K8s security audit (risk analysis + remediation guide) |
| rpc-monitor | RPC node status monitoring |
| rpc-analytics | RPC analytics engine (block traversal, tx aggregation) |
| helm-chart-auditor | Comprehensive Helm chart audit (lint, security, best practices) |
| argocd-drift-detector | Systematic ArgoCD drift detection across apps and clusters |

## Cluster Aliases

Add an `aliases` field in `clusters.yaml` to use short names for clusters:

```yaml
# skills/k8s-ops/clusters.yaml (local only, .gitignore)
clusters:
  my-cluster:
    kubeconfig: "~/.kube/my_cluster_config"
    aliases: ["dev", "my dev"]     # /k8s-ops dev → my-cluster
  my-prod:
    kubeconfig: "~/.kube/my_prod_config"
    aliases: ["prod"]              # /k8s-security prod → my-prod
```

Usage:
- `/k8s-ops dev` → matches alias `dev` → `my-cluster`
- `/k8s-security prod` → matches alias `prod` → `my-prod`
- `/k8s-ops my-cluster` → exact key match → `my-cluster`

Match priority: exact key name > alias match > partial match (prompts selection if multiple candidates)

> `clusters.yaml` is included in `.gitignore` so real cluster names are never exposed in the public repo. See `clusters.yaml.example` for configuration examples.

## Structure

```
├── skills/           # Symlinked to ~/.claude/skills/
│   ├── k8s-ops/      # K8s inspection skill + clusters.yaml (auto-generated locally)
│   ├── k8s-security/ # K8s security audit skill
│   ├── ssh-ops/      # SSH inspection skill
│   ├── rpc-health/   # RPC health check skill
│   ├── rpc-agent/    # RPC analytics agent entry point
│   │   └── scripts/  # Bundled analysis scripts (cosmos_total_tx.py, etc.)
│   ├── db-ops/       # DB query skill
│   ├── helm-ops/     # Helm chart inspection + authoring guide
│   ├── terraform-ops/ # Terraform state/plan + IaC authoring guide
│   └── argocd-ops/   # ArgoCD monitoring + GitOps manifest authoring
├── agents/           # Sub-agent definitions
│   ├── k8s-debugger.md
│   ├── k8s-security-auditor.md
│   ├── rpc-analytics.md  # RPC analytics engine (EVM + Cosmos)
│   ├── rpc-monitor.md
│   ├── helm-chart-auditor.md    # Helm chart comprehensive audit
│   └── argocd-drift-detector.md # ArgoCD drift detection
├── configs/          # Configuration templates
│   ├── settings.json.template     # allow/deny rules
│   ├── claude.md.template         # CLAUDE.md merge content
│   └── settings.local.json.example
├── scripts/          # Install/management scripts
│   ├── install.sh    # Backup → symlink → merge
│   ├── uninstall.sh
│   └── update.sh
└── templates/        # Templates for new skills/agents
```

## How Install Works

1. **Backup**: Saves existing files to `~/.claude/backups/claude-ops-skills/{timestamp}/`
2. **Symlink skills**: `skills/*` → `~/.claude/skills/*` (skips if already linked)
3. **Merge settings.json**: Adds allow/deny rules to existing config (preserves hooks, deduplicates)
4. **Merge CLAUDE.md**: Marker-based block management (`# === claude-ops-skills:start/end ===`)
5. **settings.local.json**: Never modified

## Task Complete Notification (macOS)

After `make install`, a **Stop hook** is registered that sends a macOS notification when Claude finishes a task. If you're already looking at VSCode or iTerm, the notification is suppressed.

To disable, remove the `Stop` section from `~/.claude/settings.json`:

```json
// Delete this block in ~/.claude/settings.json → hooks → Stop
"Stop": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "FRONT=$(osascript -e ...)  ..."
      }
    ]
  }
]
```

> This feature is macOS only (`osascript`). On Linux, the Stop hook will silently fail with no side effects.

## Safety

- All operations are **READ-ONLY** — no system-affecting commands are executed
  - K8s: `get`, `describe`, `logs`, `top`, `exec` (inspection only)
  - Helm: `list`, `status`, `get`, `show`, `lint`, `template`, `history`, `diff` (no install/upgrade/delete)
  - Terraform: `state list/show`, `plan`, `validate`, `fmt -check`, `output` (no apply/destroy/init)
  - ArgoCD: `app get/list/diff/logs/history`, `repo list`, `cluster list` (no sync/create/delete)
- Mutating commands are blocked by **deny rules** in settings.json + **CRITICAL SAFETY** sections in each SKILL.md
- When changes are needed, the skill provides commands as **text guidance only** — never executes them
- Chart/IaC authoring uses **Write/Edit tools** to create files locally — no infrastructure impact
- Sensitive data (kubeconfig contents, SSH keys) is never included in this repo
- `clusters.yaml` is local only — `install.sh` auto-generates it by scanning `~/.kube/` (included in `.gitignore`)

## Reference

### DevOps Skills (helm-ops, terraform-ops, argocd-ops 구현 참고)

- [antonbabenko/terraform-skill](https://github.com/antonbabenko/terraform-skill) - Terraform/OpenTofu best practices skill (testing, modules, CI/CD, production patterns)
- [akin-ozer/cc-devops-skills](https://github.com/akin-ozer/cc-devops-skills) - 31 DevOps skills (Helm/Terraform/K8s generator+validator pairs, severity classification)
- [ahmedasmar/devops-claude-skills](https://github.com/ahmedasmar/devops-claude-skills) - GitOps workflows (ArgoCD 3.x, Flux, drift detection, ApplicationSet patterns)

### Claude Code Ecosystem

- [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) - Curated list of Claude Skills, resources, and tools
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) - Skills, hooks, slash-commands, agent orchestrators
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) - 180+ production-ready skills for AI coding agents

### Architecture & Patterns

- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code plugin/agent architecture
- [claude-code-auto-approve](https://github.com/oryband/claude-code-auto-approve) - PreToolUse hook with compound command parsing (shfmt AST)
