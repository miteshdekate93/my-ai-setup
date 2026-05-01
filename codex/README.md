# OpenAI Codex CLI Setup

One-command restore of your full Codex CLI configuration on any new machine.

## Install

```bash
# macOS / Linux
bash codex/setup.sh

# Windows (run from repo root)
.\codex\setup.ps1
```

---

## What Gets Installed

| Path | What it does |
|------|-------------|
| `~/.codex/config.toml` | Model, sandbox mode, approval policy |
| `~/.codex/AGENTS.md` | Global instructions (all rules in one file) |
| `~/.codex/memory/L3/` | SOP memory directory (shared pattern with Claude setup) |
| `~/.local/bin/codex-task` | Full pipeline orchestrator (equivalent to Claude's `/task`) |
| `~/.local/bin/codex-plan` | Planning only |
| `~/.local/bin/codex-tdd` | Write failing tests first |
| `~/.local/bin/codex-review` | Code review on changed files |
| `~/.local/bin/codex-security` | Security scan on changed files |
| `./AGENTS.md` | Project-level instructions |
| `./tasks/todo.md` | Task tracking |
| `./tasks/lessons.md` | Lessons learned log |

---

## CLI Scripts

These are shell scripts installed to `~/.local/bin/` — run from any project directory.

### Full pipeline

```bash
codex-task "implement JWT authentication with refresh tokens"
codex-task "fix bug where users can delete other users' posts"
codex-task "refactor the payment module to use repository pattern"
```

Equivalent to Claude Code's `/task`. Runs all 8 phases autonomously:

1. **Branch** — `git checkout -b feat/<slug>`
2. **Plan** — numbered breakdown of changes + risks
3. **Tests (RED)** — write failing tests, run to confirm failure
4. **Implement (GREEN)** — minimal code to pass tests
5. **Code review** — check names, errors, hardcoded values, edge cases
6. **Security** — conditional scan (skipped for pure logic/UI)
7. **Crystallize SOP** — save to `~/.codex/memory/L3/` for future recall
8. **Git output** — print exact `git push` + `gh pr create` commands

### Individual phases

```bash
codex-plan "add rate limiting to the user API"
# → numbered breakdown: files, before/after, risks, dependencies

codex-tdd "user can only delete their own posts"
# → writes failing tests first, runs them to confirm RED

codex-review
# → reviews git-changed files: names, errors, hardcoded values, edge cases

codex-security
# → scans git-changed files: secrets, injection, auth, input validation
```

---

## How `codex-task` Works

### Stack detection (automatic)

| Detected file | Stack | Review focus |
|--------------|-------|-------------|
| `package.json` / `bun.lockb` | Node/TypeScript | TS types, async errors |
| `go.mod` | Go | goroutine safety, error wrapping |
| `Cargo.toml` | Rust | ownership, error propagation |
| `requirements.txt` / `pyproject.toml` | Python | type hints, exception handling |
| `build.gradle` | Kotlin/Android | null safety, coroutine scope |
| `pubspec.yaml` | Flutter/Dart | widget lifecycle, null safety |

### GitHub auth routing

| GitHub status | What happens |
|--------------|-------------|
| Authenticated | Full pipeline → outputs push + PR commands |
| Not authenticated | Full pipeline → outputs push + PR commands to run manually |

Either way, all code work (branch, tests, implement, review) runs locally first.

---

## WUPHF — Multi-Agent Orchestration

WUPHF is primarily built for Claude Code, but the same pattern applies to Codex via parallel `codex exec` sessions.

For Codex, the `codex-task` pipeline already handles multi-phase orchestration (plan → TDD → implement → review → security). Use WUPHF when you want a separate Claude Code session running alongside Codex — e.g. Claude handles architecture review while Codex implements.

```bash
npx wuphf    # starts multi-agent Claude Code session
```

---

## Stash — Persistent Cross-Session Memory

Stash gives your AI tools durable memory across sessions via an MCP server. Works with both Codex and Claude Code.

### Setup

```bash
cd ~/.stash
cp .env.example .env      # add OPENAI_API_KEY and ANTHROPIC_API_KEY
docker compose up -d
```

Config is already at `~/.stash/docker-compose.yml` (written by setup.sh).

For Codex, Stash memory can be queried by prepending context to prompts. For Claude Code, add the MCP server:
```bash
claude mcp add stash --sse http://localhost:8765/sse
```

---

## L3 Memory — Compound Speedup

Every non-trivial `codex-task` saves a reusable SOP:

```
~/.codex/memory/L3/
├── node-jwt-auth.md
├── go-grpc-service.md
├── python-db-migration.md
└── react-context-state.md
```

On the next similar task, the SOP is recalled automatically. No cold-start reasoning.

**Compound effect:** 10 similar tasks → 5x faster on the 10th.

L3 memory is compatible with Claude Code — SOPs written by one tool are readable by the other.

---

## Model Selection

Default model is `gpt-4.1`. Switch mid-session with `/model`.

| Task | Model | Switch |
|------|-------|--------|
| Simple fix, single file | gpt-4.1-mini | `/model gpt-4.1-mini` |
| Main development (default) | gpt-4.1 | — |
| Complex architecture, deep reasoning | o3 | `/model o3` |

Change default in `~/.codex/config.toml`:
```toml
model = "gpt-4.1-mini"   # cheaper for light work
```

---

## Sandbox & Approval Config

`setup.sh` sets `danger-full-access` and `ask_for_approval = "never"` — fully autonomous mode, same as Claude Code with auto-accept permissions.

To restrict for untrusted codebases:
```toml
# ~/.codex/config.toml
sandbox = "workspace-write"   # can write files, can't run arbitrary commands
ask_for_approval = "on-request"
```

---

## AGENTS.md — Instruction Files

Codex reads two instruction files, merged in order:

1. `~/.codex/AGENTS.md` — global (installed by setup.sh)
2. `./AGENTS.md` — project-specific (installed by setup.sh in current dir)

The project `AGENTS.md` overrides or extends global instructions. Edit it freely per project.

**What's in the global `~/.codex/AGENTS.md`:**
- Caveman mode (terse responses, hedge reducer)
- Coding style (immutability, file size, error handling)
- Development workflow (research → plan → TDD → review → commit)
- Git commit format (conventional commits)
- Testing requirements (80% coverage, TDD mandatory)
- Security checklist
- Model selection guide
- Context budget rules
- L3 memory crystallization rules

---

## New Project Checklist

```bash
# 1. Run setup from repo root
bash ~/path/to/codex/setup.sh

# 2. Authenticate GitHub (one-time, optional but recommended)
gh auth login

# 3. Start building
codex-task "implement <first feature>"
```

---

## GitHub Auth

Without `gh auth login`:
- `codex-task` does all code work (branch, tests, implement, review)
- Outputs exact `git push` + `gh pr create` commands to run manually

With `gh auth login`:
- Same workflow, but the git commands at the end can be run in one copy-paste
