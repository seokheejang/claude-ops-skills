# claude-ops-skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skills-blueviolet)](https://github.com/anthropics/claude-code)

Claude Code slash-command skills for DevOps daily operations.
For DevOps engineers and SREs who manage Kubernetes clusters, Helm charts, Terraform IaC, ArgoCD GitOps, and blockchain infrastructure — run read-only inspections, security audits, and best-practice research without leaving the terminal.

All operations are **READ-ONLY**. Mutating commands are blocked at the settings level and never executed.

Infrastructure skills assume the cluster/server is **not directly reachable** from the session: they emit copy-paste read-only command bundles for the operator to run, then interpret the pasted output. Chart/IaC/manifest work runs locally on files.

## Table of Contents

- [Quick Start](#quick-start)
- [Skills](#skills)
- [External Plugins & Skills](#external-plugins--skills)
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
| k8s-ops | `/k8s-ops <context>` | K8s read-only inspection — emits copy-paste `kubectl` bundles, interprets pasted output |
| k8s-craft | `/k8s-craft <resource or topic>` | K8s manifest authoring & design — our conventions and guardrails, not a YAML catalog |
| k8s-security | `/k8s-security <context>` | K8s security audit (RBAC, NetworkPolicy, Pod Security) — emits command bundles, classifies by severity |
| ssh-ops | `/ssh-ops <user@host>` | SSH server inspection — emits command bundles, checks against thresholds |
| troubleshoot | `/troubleshoot <symptom>` | Evidence-based failure-diagnosis discipline — every judgment cites observed output, fixes cross-checked from multiple angles, side effects enumerated, remediation is operator-confirmed manual guidance only |
| db-ops | `/db-ops <target>` | DB read-only inspection — composes SELECT/SHOW bundles (no DML/DDL) |
| helm-ops | `/helm-ops <context-or-chart>` | Helm chart validation (runs locally) + release inspection (command bundles) |
| terraform-ops | `/terraform-ops <directory>` | Terraform state inspection, plan analysis, IaC authoring guide |
| argocd-ops | `/argocd-ops <app>` | ArgoCD app status, sync monitoring, drift detection — emits command bundles |
| sh-craft | `/sh-craft <purpose or path>` | Shell script authoring & review — bash by default, POSIX sh fallback for minimal pod images, shellcheck/shfmt validation |
| ralph | `/ralph [N] <task>` | Self-review loop (iterative verification, default 5 rounds) — per-domain checklists for code, DevOps/IaC, analysis/debugging, config/docs |
| catchup | `/catchup` | Read-only session context restore — reads git (recent commits + uncommitted) → CLAUDE.md → README → docs, briefs what was done last & where to start |
| best-practice | `/best-practice <topic or question>` | DevOps best practice research with Citation verification, AI content detection, source independence, domain-aware recency |
| grill-me | `/grill-me` | Stress-test a plan or design via relentless one-by-one interview until shared understanding |
| write-a-skill | `/write-a-skill` | Interview-based scaffolding for new skills — enforces description/length/security conventions |
| transfer-en | `/transfer-en <한국어>` | Korean → simple, natural English for Slack/email — plain words, nothing awkward to a native speaker |
| notion-report | `/notion-report` | Work output → Korean Notion page. Routes to one of 4 vendored Notion Cookbook templates, runs at `effort: high` |

## External Plugins & Skills

Third-party Claude Code resources kept external where possible, so upstream updates arrive by `git pull` instead of going stale in this repo. Vendored only when the copy has to be patched to work here — see **Vendored** below.

**Plugins** — consumed via `/plugin` (installed manually, **not** handled by `install.sh`):

| Plugin | Marketplace | Use |
|--------|-------------|-----|
| `humanize-korean` | `epoko77-ai/im-not-ai` | De-AI Korean text (content-preserving rewrite) |
| `ponytail` | `DietrichGebert/ponytail` | Pre-generation over-engineering guardrail (YAGNI, stdlib-first) |

**Skills** (no `marketplace.json` → can't use `/plugin`) — declared in `configs/external-skills.tsv`, reproduced by `install.sh` (clone → npm → symlink, cloned outside the repo, updated via `git pull`):

No active entries. The mechanism stays in place — add one TAB-separated line to `configs/external-skills.tsv` and re-run `install.sh` to register a new external skill. (Previously carried `archify`, disabled 2026-07-09 — see [docs/external-plugins.md](docs/external-plugins.md).)

**Vendored** — copied into `skills/` because the files had to be modified. These do **not** receive upstream updates:

| Path | Source | Commit | Local changes |
|------|--------|--------|---------------|
| `skills/notion-report/{knowledge-capture,meeting-intelligence,research-documentation,spec-to-implementation}/` | [makenotion/claude-code-notion-plugin](https://github.com/makenotion/claude-code-notion-plugin) → `skills/notion/` | `9847f2a` (2026-01-22) | tool names `Notion:` prefix → `mcp__claude_ai_Notion__*`; each `SKILL.md` → `GUIDE.md`; `evaluations/`, all `examples/`, and 5 how-to `reference/` files dropped |

Why vendored instead of an `external-skills.tsv` entry: we reach Notion through the claude.ai connector, not the plugin's bundled MCP server, so the upstream tool names do not resolve here — the files need patching, which a clone-and-symlink cannot carry. Upstream has no LICENSE file. The router `SKILL.md` is ours; the full change list is in its [출처 section](skills/notion-report/SKILL.md).

→ Install commands, update notes, and role-vs-builtin guidance: [docs/external-plugins.md](docs/external-plugins.md)

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
| `shellcheck` | For sh-craft skill | Shell script linting (bashism, POSIX compatibility) |
| `shfmt` | For sh-craft skill | Shell script formatting — `brew install shellcheck shfmt` |

> Only `Claude Code` and `make` are required. Other tools are needed only for their respective skills.

## Structure

```
├── skills/           # Symlinked to ~/.claude/skills/
│   ├── k8s-ops/      # K8s inspection — emits kubectl command bundles
│   ├── k8s-craft/    # K8s manifest authoring & design (paired with k8s-ops)
│   ├── k8s-security/ # K8s security audit skill
│   ├── ssh-ops/      # SSH inspection skill
│   ├── troubleshoot/ # Evidence-based failure-diagnosis discipline (no-speculation, manual-remediation guardrails)
│   ├── db-ops/       # DB query skill
│   ├── helm-ops/     # Helm chart inspection + authoring guide
│   ├── terraform-ops/ # Terraform state/plan + IaC authoring guide
│   ├── argocd-ops/   # ArgoCD monitoring + GitOps manifest authoring
│   ├── sh-craft/     # Shell script authoring — bash default, POSIX fallback for minimal pod images
│   ├── ralph/        # Self-review loop (iterative verification, any task type)
│   │   └── references/ # Domain checklists (code/IaC/analysis/docs) + FAIL/NOTE policy
│   ├── catchup/      # Session context restore (git + CLAUDE.md/README/docs)
│   ├── best-practice/ # DevOps best practice research
│   │   └── references/ # 3 topics (sources, verification, output)
│   ├── grill-me/     # Plan/design stress-test via relentless interview
│   ├── write-a-skill/ # Meta-skill: scaffold new skills with conventions
│   ├── transfer-en/  # Korean → simple natural English (single-file skill)
│   └── notion-report/ # Work output → Korean Notion page (router SKILL.md, effort: high)
│       ├── knowledge-capture/       # ← vendored from makenotion/claude-code-notion-plugin @9847f2a
│       ├── meeting-intelligence/    #   tool names rewritten to mcp__claude_ai_Notion__*,
│       ├── research-documentation/  #   SKILL.md → GUIDE.md, evaluations/+examples/ dropped
│       └── spec-to-implementation/  #   (see the 출처 section in notion-report/SKILL.md)
├── configs/          # Configuration templates
│   ├── settings.json.template     # allow/deny rules
│   ├── claude.md.template         # CLAUDE.md merge content
│   ├── external-skills.tsv        # External skills to clone + symlink (not plugins)
│   └── settings.local.json.example
├── scripts/          # Install/management scripts
│   ├── install.sh    # Backup → symlink → merge
│   ├── uninstall.sh
│   └── update.sh
├── templates/        # Templates for new skills
└── _disabled/        # Skills kept in repo but excluded from install (not under skills/*)
    ├── mmdraw/       # Mermaid diagram generator — re-enable with `mv _disabled/mmdraw skills/`
    └── humanize-ko/  # Superseded by humanize-korean plugin (see docs/external-plugins.md)
```

<details>
<summary><strong>How Install Works</strong></summary>

1. **Backup**: Saves existing files to `~/.claude/backups/claude-ops-skills/{timestamp}/`
2. **Symlink skills**: `skills/*` → `~/.claude/skills/*` (skips if already linked), then **prunes** links left behind by skills deleted from the repo — only links pointing into this repo whose target is gone; other repos' links are left alone
3. **External skills**: clones each entry in `configs/external-skills.tsv` to `~/.claude/external-skills/` (`EXTERNAL_SKILLS_DIR`), runs `npm install` if needed, then symlinks — all idempotent
4. **Merge settings.json**: Adds allow/deny rules to existing config (preserves hooks, deduplicates)
5. **Merge CLAUDE.md**: Marker-based block management (`# === claude-ops-skills:start/end ===`)
6. **settings.local.json**: Never modified

> External **plugins** (with a marketplace) are **not** handled by install.sh — install them manually via `/plugin`. External **skills** (no marketplace) are. See [docs/external-plugins.md](docs/external-plugins.md).

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
- Mutating commands are blocked by **deny rules** in settings.json (the enforcement layer) and restated in each SKILL.md
- When changes are needed, the skill provides commands as **text guidance only** — never executes them
- Chart/IaC authoring uses **Write/Edit tools** to create files locally — no infrastructure impact
- Sensitive data (kubeconfig contents, SSH keys) is never included in this repo
- Cluster contexts are supplied by the operator via `--context` — no cluster inventory is stored in this repo

## Reference

### DevOps Skills

- [antonbabenko/terraform-skill](https://github.com/antonbabenko/terraform-skill) - Terraform/OpenTofu best practices skill (testing, modules, CI/CD, production patterns)
- [akin-ozer/cc-devops-skills](https://github.com/akin-ozer/cc-devops-skills) - 31 DevOps skills (Helm/Terraform/K8s generator+validator pairs, severity classification)
- [ahmedasmar/devops-claude-skills](https://github.com/ahmedasmar/devops-claude-skills) - GitOps workflows (ArgoCD 3.x, Flux, drift detection, ApplicationSet patterns)

### Diagram & Visualization

- [mermaid-to-excalidraw](https://mermaid-to-excalidraw.vercel.app/) - Mermaid → Excalidraw web converter

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
