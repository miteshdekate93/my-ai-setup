# My AI Setup

One-command setup for **Claude Code** and **OpenAI Codex CLI** — restores all rules, workflows, commands, and memory on any new machine in seconds.

---

## Structure

```
my-ai-setup/
├── claude/
│   ├── setup.sh        macOS / Linux
│   ├── setup.ps1       Windows (PowerShell)
│   └── README.md       Claude-specific guide
├── codex/
│   ├── setup.sh        macOS / Linux
│   ├── setup.ps1       Windows (PowerShell)
│   └── README.md       Codex-specific guide
└── README.md           this file
```

---

## Quick Start

### Claude Code — macOS/Linux
```bash
bash claude/setup.sh
```

### Claude Code — Windows
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser   # one-time
.\claude\setup.ps1
```

### OpenAI Codex CLI — macOS/Linux
```bash
bash codex/setup.sh
```

### OpenAI Codex CLI — Windows
```powershell
.\codex\setup.ps1
```

---

## Smart Defaults For Your Stack

This setup is tuned for React, Angular, C#/.NET, Azure, SQL Server, Oracle, Claude, and Codex work. It avoids Python-first guidance unless a repo is actually Python or you explicitly ask.

Simple prompts still trigger the smarter workflow: check git status, load project rules and lessons, recall L3 memory, use GitNexus for impact, search reuse with rg/git grep, choose the smallest safe implementation, run focused checks, and avoid commit/push unless asked.

Reviewed GitHub ideas folded in:

| Idea/tool | How setup uses it |
|-----------|-------------------|
| Ponytail minimal-safe ladder | Reuse/native/framework first, smallest safe change, no unnecessary packages |
| prop-for-that | Native browser/CSS-first frontend state before JS render loops |
| nubase / Nub | Schema-first CRUD/admin thinking; optional Node/TypeScript command acceleration when compatible |
| LikeC4 | Architecture-as-code cue for ADRs/diagrams when architecture changes |
| jcode/ReCall | Tool evidence, memory recall, and multi-step tool reasoning before claims |
| Rowboat | Local-first, inspectable Markdown memory and project knowledge graph habits |
| Engram | Optional indexed MCP memory: search previous lessons before planning, save compact learnings after work |
| Firecrawl | Optional LLM-ready web context: clean Markdown/structured extraction for current docs/pages |
| no-mistakes | Optional push gate: isolated validation before branch/PR reaches origin |
| Herdr / Orca | Optional fleet mode: parallel agents in terminals/worktrees only for complex independent work |
| Exo | Optional, isolated long-running agent sidecar for user-approved scheduled research, monitoring, and sandbox experiments |
| AirLLM | Not adopted by default; Python/model-inference focus does not match daily stack |

## What Each Setup Installs

| What | Claude Code | Codex CLI |
|------|------------|-----------|
| Global config | `~/.claude/settings.json` | `~/.codex/config.toml` |
| Global rules/instructions | `~/.claude/rules/*.md` | `~/.codex/AGENTS.md` |
| Project instructions | `CLAUDE.md` | `AGENTS.md` |
| Global BMAD skills | `~/.claude/skills/bmad-*` | `~/.codex/skills/bmad-*` |
| Full pipeline command | `/task` (slash command) | `codex-task` (CLI script) |
| Planning command | `/plan` (ECC skill) | `codex-plan` |
| TDD / focused test command | `/tdd` (when tests requested) | `codex-tdd` |
| Code review command | `/code-review` (ECC skill) | `codex-review` |
| Security scan command | `/security-scan` (ECC skill) | `codex-security` |
| Memory (L3 SOPs) | `~/.claude/memory/L3/` | `~/.codex/memory/L3/` |
| Cross-session memory | Stash MCP (`~/.stash/`) + optional Engram | Stash MCP (`~/.stash/`) + optional Engram |
| Multi-agent / cache | WUPHF (`npx wuphf`) + optional Herdr/Orca | WUPHF pattern + optional Herdr/Orca |
| Workflow engine | Archon CLI (auto-dispatched), optional no-mistakes push gate | built-in 8-phase pipeline, optional no-mistakes push gate |

---

## 10x Speed Tactics — Both Tools

### 1. One-command pipeline

Instead of manually planning, branching, writing tests, implementing, reviewing, and pushing:

```bash
# Claude Code
/task "implement JWT authentication"

# Codex CLI
codex-task "implement JWT authentication"
```

Both tools auto-detect your stack, create a branch, plan verification, implement, review, security-scan, then output git push commands (or push automatically if GitHub is authenticated).

### 2. Plan before every feature (saves rework)

```bash
/plan "add rate limiting to the API"       # Claude
codex-plan "add rate limiting to the API"  # Codex
```

5 minutes of planning prevents 2 hours of rework.

### 3. TDD — tests force clarity

```bash
/tdd "user can only delete their own posts"   # Claude
codex-tdd "user can only delete their own posts"  # Codex
```

Run existing focused checks first. Add tests when requested, repo pattern expects it, or bug/high-risk behavior needs regression coverage.

### 4. WUPHF — 97% cache hit rate, fresh context per agent

WUPHF orchestrates multiple Claude Code agents with fresh sessions per turn — prevents the context accumulation that slows long tasks.

| Metric | Single session | WUPHF |
|--------|---------------|-------|
| Tokens per turn | 484k accumulated | ~40k fresh |
| Cache hit rate | varies | 97% |
| Agent roles | one | CEO + PM + Engineer + Reviewer |

```bash
npx wuphf    # Claude Code only
```

Use when: long refactors, parallel planning + implementation, architecture reviews.

### 5. Scout + Researcher — eliminate cold-start planning

Before every complex feature, run scout (codebase recon) + researcher (external docs) in parallel.
Scout writes `context.md`, Researcher writes `external-reference.md`. Planner reads both.
Eliminates the "cold start" where the AI reasons from scratch about your codebase.

Built into `/task` and `codex-task` automatically — no extra command needed.

### 6. Stash — persistent memory across sessions (no re-explaining)

Stash is a self-hosted MCP server that remembers what Claude learned last session.

```bash
cd ~/.stash && docker compose up -d
claude mcp add stash --sse http://localhost:8765/sse
```

Config is already at `~/.stash/docker-compose.yml`. Fill in `.env` with your API keys.

### 7. L3 Memory — never solve the same problem twice

Every `/task` or `codex-task` crystallizes a reusable SOP in `~/.*/memory/L3/`.
On the next similar task it's recalled automatically — skips cold-start reasoning.

```
First JWT task:    normal speed
Second JWT task:   2-3x faster (SOP recalled)
Tenth JWT task:    5x faster (proven pattern + gotchas memorized)
```

### 8. Caveman mode — 65% fewer output tokens (Claude only)

Always active. Drops filler, articles, hedging — keeps full technical accuracy.
Faster responses, longer sessions before context limit.

### 9. Model routing

| Task | Claude model | Codex model |
|------|-------------|-------------|
| Simple fix, single file | Haiku 4.5 | gpt-4.1-mini |
| Main development work | Sonnet 4.6 (default) | gpt-4.1 (default) |
| Complex architecture / deep reasoning | Opus 4.5 | o3 |

Switch mid-session:
- Claude: `/model claude-haiku-4-5` or `/model claude-opus-4-5`
- Codex: `/model gpt-4.1-mini` or `/model o3`

---

## New Project Checklist

Run this once when starting any new project:

```bash
# 1. Clone / init repo
git clone <repo> && cd <repo>

# 2. Run setup for your tool (drops project instructions + tasks/)
bash ~/path/to/my-ai-setup/claude/setup.sh    # → writes CLAUDE.md
bash ~/path/to/my-ai-setup/codex/setup.sh     # → writes AGENTS.md

# 3. (Claude only) Index codebase with GitNexus for deep code intelligence
/gitnexus-init

# 4. Create CONTEXT.md (one-time per project — 10 min)
# Add domain terms + key architectural decisions
# See docs: what to put in CONTEXT.md

# 5. Optional: authenticate GitHub for auto-push + auto-PR
gh auth login

# 5. Start building
/task "implement <first feature>"           # Claude
codex-task "implement <first feature>"      # Codex
```

---

## Requirements

| Tool | Install |
|------|---------|
| Claude Code | `npm install -g @anthropic-ai/claude-code` |
| Codex CLI | `npm install -g @openai/codex` |
| GitHub CLI | `brew install gh` (optional — enables auto-push + PR) |
| Archon CLI | auto-installed by `claude/setup.sh` |
| Node.js 18+ | required for both CLIs |
| Nub | optional Node/TypeScript speed tool; use only when compatible with repo scripts |
| Engram | optional indexed memory MCP/plugin |
| Firecrawl | optional real-time web context MCP/skill; requires API key |
| no-mistakes | optional push/PR validation gate |
| Herdr / Orca | optional agent fleet/worktree orchestration |

---

## Exo Harness - Opt-in Durable Sidecar

[Exo](https://github.com/exoharness/exo) adds a separate long-running agent runtime: its own Docker sandbox, API-key-backed model access, scheduler, adapters, and durable event history. It does not replace Codex or Claude Code.

Use it only where current setup has a gap: user-approved scheduled research, monitoring, or sandbox experiments that must survive a normal coding session. Keep code changes, reviews, GitNexus impact checks, and focused verification in Codex or Claude Code.

| Runtime | Owns |
|---------|------|
| Codex / Claude Code | Repository work, review, validation, project rules, L2/L3 memory |
| Exo | Isolated long-running sidecar work with explicit scope and human review |

Exo is intentionally **not** installed by these setup scripts. Upstream Quick Start is Bash-based and requires Git, Docker, plus an OpenAI or OpenRouter API key. On Windows, use a separate WSL2 and Docker Desktop environment only after reviewing upstream setup and confirming network exposure, persistent-state location, and cost limits.

Start Exo without repository write access, Git/cloud credentials, production secrets, or autonomous external actions. Promote any output through Codex or Claude Code review. Keep its clone and state separate from Codex/Claude global directories and this setup repository.

---

## Detailed Guides

- [Claude Code setup, skills, and workflow →](claude/README.md)
- [Codex CLI setup, scripts, and workflow →](codex/README.md)
