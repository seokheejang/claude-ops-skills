# claude-ops-skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skills%20%26%20Agents-blueviolet)](https://github.com/anthropics/claude-code)

Claude Code slash-command skills and agents for DevOps daily operations.
For DevOps engineers and SREs who manage Kubernetes clusters, Helm charts, Terraform IaC, ArgoCD GitOps, and blockchain infrastructure — run read-only inspections, security audits, and best-practice research without leaving the terminal.

All operations are **READ-ONLY by default**. Mutating commands are blocked at the settings level and never executed.

## Table of Contents

- [Quick Start](#quick-start)
- [Skills](#skills)
- [Agents](#agents)
- [Prerequisites](#prerequisites)
- [Structure](#structure)
- [Safety](#safety)
- [Reference](#reference)

## Quick Start

```bash
git clone https://github.com/seokheejang/claude-ops-skills.git
cd claude-ops-skills
make install
```

Then restart Claude Code and try:

```
/k8s-ops my-cluster          # Inspect a K8s cluster
/helm-ops my-release          # Check Helm release status
/best-practice EKS CNI choice # Research industry best practices
```

Other commands:

```bash
make update     # git pull + reinstall
make uninstall  # Uninstall
make test       # Run PreToolUse hook tests
```

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| k8s-ops | `/k8s-ops <cluster>` | K8s cluster inspection (get, describe, logs, top) — paired with k8s-craft for authoring |
| k8s-craft | `/k8s-craft <resource or topic>` | K8s manifest authoring & design (workloads, networking, storage, RBAC, NetworkPolicy, cost, operators, mesh, multi-cluster) |
| k8s-security | `/k8s-security <cluster>` | K8s security audit (RBAC, NetworkPolicy, Pod Security) |
| ssh-ops | `/ssh-ops <host>` | SSH server inspection |
| troubleshoot | `/troubleshoot <symptom>` | Evidence-based failure-diagnosis discipline — every judgment cites observed output, fixes cross-checked from multiple angles, side effects enumerated, remediation is operator-confirmed manual guidance only |
| rpc-health | `/rpc-health <endpoint>` | Blockchain RPC node health check |
| rpc-agent | `/rpc-agent <endpoint> <module>` | RPC analytics agent (block traversal, tx counting) |
| db-ops | `/db-ops <database>` | DB read-only queries (SELECT, SHOW only) |
| helm-ops | `/helm-ops <cluster-or-chart>` | Helm chart validation, release inspection, chart authoring guide |
| terraform-ops | `/terraform-ops <directory>` | Terraform state inspection, plan analysis, IaC authoring guide |
| argocd-ops | `/argocd-ops <app-or-context>` | ArgoCD app status, sync monitoring, drift detection, GitOps manifest authoring |
| ralph | `/ralph [N] <task>` | Self-review loop (iterative verification, default 5 rounds) |
| mmdraw | `/mmdraw <target>` | Mermaid diagram generator from source/docs analysis (→ Excalidraw manual conversion) |
| compound | `/compound [completed\|paused] <desc>` | Work synthesis - learnings capture, doc lifecycle, CHANGELOG update |
| catchup | `/catchup` | Read-only session context restore — reads git (recent commits + uncommitted) → CLAUDE.md → README → docs, briefs what was done last & where to start |
| best-practice | `/best-practice <topic or question>` | DevOps best practice research with Citation verification, AI content detection, source independence, domain-aware recency |
| grill-me | `/grill-me` | Stress-test a plan or design via relentless one-by-one interview until shared understanding |
| write-a-skill | `/write-a-skill` | Interview-based scaffolding for new skills — enforces description/length/security conventions |
| transfer-en | `/transfer-en <한국어>` | Korean → easy conversational English (CEFR A2) with casual alternative + auto-accumulating learning notes |

## Agents

| Agent | Description |
|-------|-------------|
| k8s-debugger | Systematic K8s issue debugging |
| k8s-security-auditor | Comprehensive K8s security audit (risk analysis + remediation guide) |
| rpc-monitor | RPC node status monitoring |
| rpc-analytics | RPC analytics engine (block traversal, tx aggregation) |
| helm-chart-auditor | Comprehensive Helm chart audit (lint, security, best practices) |
| argocd-drift-detector | Systematic ArgoCD drift detection across apps and clusters |

## Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| [Claude Code](https://github.com/anthropics/claude-code) | Yes | CLI runtime for skills |
| `make` | Yes | Install/update/uninstall |
| `kubectl` | For K8s skills | K8s cluster inspection |
| `helm` | For Helm skills | Chart validation, release inspection |
| `terraform` | For Terraform skills | State inspection, plan analysis |
| `argocd` | For ArgoCD skills | App status, sync monitoring |
| `ssh` | For SSH skills | Server inspection |

> Only `Claude Code` and `make` are required. Other tools are needed only for their respective skills.

<details>
<summary><strong>Cluster Aliases</strong></summary>

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

</details>

## Structure

```
├── skills/           # Symlinked to ~/.claude/skills/
│   ├── k8s-ops/      # K8s inspection skill + clusters.yaml (auto-generated locally)
│   │   └── references/ # Troubleshooting deep-dive
│   ├── k8s-craft/    # K8s manifest authoring & design (paired with k8s-ops)
│   │   └── references/ # 8 topics (workloads, networking, storage, ...)
│   ├── k8s-security/ # K8s security audit skill
│   ├── ssh-ops/      # SSH inspection skill
│   ├── troubleshoot/ # Evidence-based failure-diagnosis discipline (no-speculation, manual-remediation guardrails)
│   ├── rpc-health/   # RPC health check skill
│   ├── rpc-agent/    # RPC analytics agent entry point
│   │   └── scripts/  # Bundled analysis scripts (cosmos_total_tx.py, etc.)
│   ├── db-ops/       # DB query skill
│   ├── helm-ops/     # Helm chart inspection + authoring guide
│   │   └── references/ # Chart authoring deep-dive (structure, values, templates, hooks, testing)
│   ├── terraform-ops/ # Terraform state/plan + IaC authoring guide
│   ├── argocd-ops/   # ArgoCD monitoring + GitOps manifest authoring
│   │   └── references/ # GitOps deep-dive (ArgoCD/Flux install, AppSet, sealed secrets)
│   ├── ralph/        # Self-review loop (iterative verification)
│   │   └── references/ # Domain checklists + FAIL/NOTE judgement policy
│   ├── mmdraw/       # Mermaid diagram generator (→ Excalidraw conversion)
│   ├── compound/     # Work synthesis - learnings, doc lifecycle, CHANGELOG
│   │   └── references/ # 3 topics (work-doc, learnings, changelog)
│   ├── catchup/      # Session context restore (git + CLAUDE.md/README/docs)
│   ├── best-practice/ # DevOps best practice research
│   │   └── references/ # 3 topics (sources, verification, output)
│   ├── grill-me/     # Plan/design stress-test via relentless interview
│   ├── write-a-skill/ # Meta-skill: scaffold new skills with conventions
│   └── transfer-en/  # Korean → easy English translator + learning note system (local-only learning.md/pending.md)
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

<details>
<summary><strong>How Install Works</strong></summary>

1. **Backup**: Saves existing files to `~/.claude/backups/claude-ops-skills/{timestamp}/`
2. **Symlink skills**: `skills/*` → `~/.claude/skills/*` (skips if already linked)
3. **Merge settings.json**: Adds allow/deny rules to existing config (preserves hooks, deduplicates)
4. **Merge CLAUDE.md**: Marker-based block management (`# === claude-ops-skills:start/end ===`)
5. **settings.local.json**: Never modified

</details>

<details>
<summary><strong>Task Complete Notification (macOS)</strong></summary>

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

</details>

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

### DevOps Skills

- [antonbabenko/terraform-skill](https://github.com/antonbabenko/terraform-skill) - Terraform/OpenTofu best practices skill (testing, modules, CI/CD, production patterns)
- [akin-ozer/cc-devops-skills](https://github.com/akin-ozer/cc-devops-skills) - 31 DevOps skills (Helm/Terraform/K8s generator+validator pairs, severity classification)
- [ahmedasmar/devops-claude-skills](https://github.com/ahmedasmar/devops-claude-skills) - GitOps workflows (ArgoCD 3.x, Flux, drift detection, ApplicationSet patterns)

### Diagram & Visualization

- [mermaid-to-excalidraw](https://mermaid-to-excalidraw.vercel.app/) - Mermaid → Excalidraw web converter (used with `mmdraw` skill output)

### Compound Engineering

- [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) - Official Compound Engineering plugin (Plan→Work→Review→Compound)
- [Compound Engineering: How Every Codes With Agents](https://every.to/chain-of-thought/compound-engineering-how-every-codes-with-agents) - Original article (Kieran Klaassen, 2025)

### Claude Code Ecosystem

- [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) - Curated list of Claude Skills, resources, and tools
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) - Skills, hooks, slash-commands, agent orchestrators
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) - 180+ production-ready skills for AI coding agents

### Architecture & Patterns

- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) - Production-grade AI harness (agents, skills, hooks, AgentShield, instincts)
- [wshobson/agents](https://github.com/wshobson/agents) - Claude Code plugin/agent architecture
- [claude-code-auto-approve](https://github.com/oryband/claude-code-auto-approve) - PreToolUse hook with compound command parsing (shfmt AST)
