# claude-ops-skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skills%20%26%20Agents-blueviolet)](https://github.com/anthropics/claude-code)

Claude Code Skills & Agents for DevOps workflows.
Reusable skills for K8s troubleshooting, blockchain RPC monitoring, DB inspection, and SSH server checks.

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

## Agents

| Agent | Description |
|-------|-------------|
| k8s-debugger | Systematic K8s issue debugging |
| k8s-security-auditor | Comprehensive K8s security audit (risk analysis + remediation guide) |
| rpc-monitor | RPC node status monitoring |
| rpc-analytics | RPC analytics engine (block traversal, tx aggregation) |

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
│   └── db-ops/       # DB query skill
├── agents/           # Sub-agent definitions
│   ├── rpc-analytics.md  # RPC analytics engine (EVM + Cosmos)
│   ├── k8s-debugger.md
│   ├── k8s-security-auditor.md
│   └── rpc-monitor.md
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

- All K8s operations are **READ-ONLY** (get, describe, logs, top, exec for inspection)
- Mutating kubectl commands (apply, delete, patch, etc.) are blocked by deny rules + CLAUDE.md directives
- Sensitive data (kubeconfig contents, SSH keys) is never included in this repo
- `clusters.yaml` is local only — `install.sh` auto-generates it by scanning `~/.kube/` (included in `.gitignore`)

## Reference

- [cc-devops-skills](https://github.com/akin-ozer/cc-devops-skills) - DevOps skill structure and SKILL.md patterns
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code plugin/agent architecture
- [claude-code-auto-approve](https://github.com/oryband/claude-code-auto-approve) - PreToolUse hook with compound command parsing (shfmt AST)
