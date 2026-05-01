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

## What Each Setup Installs

| What | Claude Code | Codex CLI |
|------|------------|-----------|
| Global config | `~/.claude/settings.json` | `~/.codex/config.toml` |
| Global rules/instructions | `~/.claude/rules/*.md` | `~/.codex/AGENTS.md` |
| Project instructions | `CLAUDE.md` | `AGENTS.md` |
| Full pipeline command | `/task` (slash command) | `codex-task` (CLI script) |
| Planning command | `/plan` (ECC skill) | `codex-plan` |
| TDD command | `/tdd` (ECC skill) | `codex-tdd` |
| Code review command | `/code-review` (ECC skill) | `codex-review` |
| Security scan command | `/security-scan` (ECC skill) | `codex-security` |
| Memory (L3 SOPs) | `~/.claude/memory/L3/` | `~/.codex/memory/L3/` |
| Cross-session memory | Stash MCP (`~/.stash/`) | Stash MCP (`~/.stash/`) |
| Multi-agent / cache | WUPHF (`npx wuphf`) | WUPHF (with Claude Code) |
| Workflow engine | Archon CLI (auto-dispatched) | built-in 8-phase pipeline |

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

Both tools auto-detect your stack, create a branch, write failing tests, implement, review, security-scan, then output git push commands (or push automatically if GitHub is authenticated).

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

Writing tests first exposes ambiguity before you write code.

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

### 5. Stash — persistent memory across sessions (no re-explaining)

Stash is a self-hosted MCP server that remembers what Claude learned last session.

```bash
cd ~/.stash && docker compose up -d
claude mcp add stash --sse http://localhost:8765/sse
```

Config is already at `~/.stash/docker-compose.yml`. Fill in `.env` with your API keys.

### 6. L3 Memory — never solve the same problem twice

Every `/task` or `codex-task` crystallizes a reusable SOP in `~/.*/memory/L3/`.
On the next similar task it's recalled automatically — skips cold-start reasoning.

```
First JWT task:    normal speed
Second JWT task:   2-3x faster (SOP recalled)
Tenth JWT task:    5x faster (proven pattern + gotchas memorized)
```

### 7. Caveman mode — 65% fewer output tokens (Claude only)

Always active. Drops filler, articles, hedging — keeps full technical accuracy.
Faster responses, longer sessions before context limit.

### 8. Model routing

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

# 4. Optional: authenticate GitHub for auto-push + auto-PR
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

---

## Detailed Guides

- [Claude Code setup, skills, and workflow →](claude/README.md)
- [Codex CLI setup, scripts, and workflow →](codex/README.md)
