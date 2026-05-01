# Claude Code Setup

One-command restore of your full Claude Code configuration on any new machine.

## Install

```bash
# macOS / Linux
bash claude/setup.sh

# Windows (run from repo root)
.\claude\setup.ps1
```

Restart Claude Code after running.

---

## What Gets Installed

| Path | What it does |
|------|-------------|
| `~/.claude/settings.json` | Voice enabled, disabled MCP servers |
| `~/.claude/rules/agents.md` | Agent table + parallel execution rules |
| `~/.claude/rules/coding-style.md` | Immutability, file size, error handling |
| `~/.claude/rules/development-workflow.md` | Research → plan → TDD → review pipeline |
| `~/.claude/rules/git-workflow.md` | Conventional commits + PR process |
| `~/.claude/rules/hooks.md` | Hook types + TodoWrite best practices |
| `~/.claude/rules/patterns.md` | Repository pattern, API response format |
| `~/.claude/rules/performance.md` | Model selection, context management, plan mode |
| `~/.claude/rules/security.md` | Security checklist + response protocol |
| `~/.claude/rules/testing.md` | TDD workflow, 80% coverage requirement |
| `~/.claude/rules/caveman.md` | Always-on token compression + hedge reducer |
| `~/.claude/rules/archon.md` | Auto-dispatch impl/fix/build to Archon workflows |
| `~/.claude/rules/memory-crystallization.md` | L3 SOP memory: search before, crystallize after |
| `~/.claude/rules/context-budget.md` | Batch tool calls, compress, spawn subagents |
| `~/.claude/commands/task.md` | `/task` — full 8-phase pipeline command |
| `~/.claude/commands/gitnexus-init.md` | `/gitnexus-init` — codebase intelligence setup |
| `~/.claude/memory/L3/` | SOP memory directory |
| `~/.archon/config.yaml` | Archon config pointing to Claude binary |
| `./CLAUDE.md` | Project-level workflow instructions |
| `./tasks/todo.md` | Task tracking |
| `./tasks/lessons.md` | Lessons learned log |

---

## Slash Commands (Skills)

These are available in every Claude Code session after setup.

### Pipeline commands

| Command | What it does |
|---------|-------------|
| `/task "implement X"` | Full pipeline: detect stack → L3 recall → branch → plan → TDD → implement → review → security → SOP → git output |
| `/plan "feature X"` | Breakdown: files, before/after, risks, dependencies |
| `/tdd "logic X"` | Write failing tests first (RED phase) |
| `/gitnexus-init` | Index codebase for dependency analysis + impact tracing |

### ECC Skills (from everything-claude-code marketplace)

Install ECC once: `claude mcp install everything-claude-code`

| Skill | Trigger |
|-------|---------|
| `/code-review` | Review changed files: names, errors, logic, edge cases |
| `/security-scan` | Scan for hardcoded secrets, injection, auth bypasses |
| `/security-review` | Deep security analysis |
| `/python-review` | Python-specific code review |
| `/go-review` | Go-specific code review |
| `/rust-review` | Rust-specific code review |
| `/kotlin-review` | Kotlin/Android code review |
| `/go-build` | Fix Go build/vet errors |
| `/rust-build` | Fix Rust/Cargo errors |
| `/kotlin-build` | Fix Kotlin/Gradle errors |
| `/gradle-build` | Fix Gradle build errors |
| `/docs` | Update documentation + codemaps |
| `/prune` | Remove dead code and unused dependencies |
| `/prompt-optimize` | Optimize prompts for LLM pipelines |

---

## How `/task` Works

`/task` is the single command that replaces the entire dev workflow.

```
/task implement JWT authentication with refresh tokens
/task fix bug where users can delete other users' posts
/task refactor the payment module to use repository pattern
/task fix issue #42
/task review PR #17
```

### Routing logic

| Request type | GitHub authed | Not authed |
|-------------|--------------|-----------|
| New feature / implement / build | Archon `archon-piv-loop` → PR | Inline pipeline |
| Fix bug / fix issue #N | Archon `archon-fix-github-issue` → PR | Inline pipeline |
| Review PR #N | Archon `archon-smart-pr-review` | Read-only review |
| Refactor / simple fix | Inline pipeline | Inline pipeline |
| Question / explain | Answered directly | Answered directly |

### Inline pipeline phases (when not using Archon)

1. **Branch** — `git checkout -b feat/<slug>`
2. **Plan** — numbered breakdown of changes + risks
3. **Tests (RED)** — write failing tests, run to confirm failure
4. **Implement (GREEN)** — minimal code to pass tests
5. **Code review** — stack-aware review agent (auto-selected)
6. **Security** — conditional scan (skipped for pure logic/UI)
7. **Crystallize SOP** — save to `~/.claude/memory/L3/` for future recall
8. **Git output** — always print exact `git push` + `gh pr create` commands

---

## Archon — Auto Workflow Engine

Archon runs plan → implement → validate → PR in an isolated worktree, in the background.

Auto-triggered whenever you say:

| Phrase | Archon workflow |
|--------|----------------|
| "implement X" / "build X" / "create feature" | `archon-piv-loop` |
| "fix issue #N" / "fix bug in X" | `archon-fix-github-issue` |
| "refactor X" | `archon-assist` |
| "review PR #N" | `archon-smart-pr-review` |
| "create a PRD" / "plan this feature" | `archon-interactive-prd` |

Skipped for: questions, single-line fixes, reading files, running tests.

Install Archon: auto-installed by `setup.sh`. If missing:
```bash
curl -fsSL https://archon.diy/install | bash
```

---

## WUPHF — Multi-Agent Orchestration (97% Cache Hit Rate)

WUPHF runs multiple Claude Code agents with fresh sessions per turn. Prevents context bloat and maximises prompt cache hits.

| Without WUPHF | With WUPHF |
|--------------|-----------|
| Single session accumulates 484k tokens | Fresh session per turn: ~40k tokens |
| Cache hit rate varies | 97% cache hit rate |
| One agent does everything | Planner + Implementer + Reviewer in parallel |

### When to use

- Long features where context gets heavy mid-task
- Architecture decisions needing multiple perspectives
- Anything where you'd normally open a fresh Claude session manually

### How to start

```bash
npx wuphf
```

WUPHF reads your existing Claude Code CLI. Agents: CEO, PM, Engineer, Reviewer.

### When NOT to use

Simple fixes or questions — `/task` inline is faster for single-phase work.

---

## Stash — Persistent Cross-Session Memory

Stash is an MCP server that gives Claude durable memory across sessions. Claude remembers what was debugged, what patterns worked, what was decided — no re-explaining every session.

### How it works

- 8-stage consolidation pipeline: raw observations → compressed facts → semantic memory
- pgvector similarity search retrieves relevant memories per query
- Self-hosted via Docker (no external service)

### Setup

```bash
cd ~/.stash
cp .env.example .env      # add ANTHROPIC_API_KEY
docker compose up -d
claude mcp add stash --sse http://localhost:8765/sse
```

Config is already at `~/.stash/docker-compose.yml` (written by setup.sh).

### When to use

- Projects that span multiple days / sessions
- Debugging complex issues where context from yesterday matters
- Any long-running refactor where patterns repeat

---

## L3 Memory — Compound Speedup

Every non-trivial `/task` saves a reusable SOP:

```
~/.claude/memory/L3/
├── node-jwt-auth.md
├── go-grpc-service.md
├── python-alembic-migration.md
└── react-context-state.md
```

On the next similar task, Claude recalls the SOP automatically. No cold-start reasoning.

**Compound effect:** 10 similar tasks → 5x faster on the 10th.

---

## Token Efficiency

### Caveman mode (always on)
Drops filler words, articles, pleasantries, hedging from all prose.
Keeps full technical accuracy. Code blocks unchanged.

- ~65% fewer output tokens
- Faster responses
- Longer sessions before hitting context limit

Switch intensity: `/caveman lite` | `/caveman full` | `/caveman ultra`
Stop: "normal mode"

### Context budget rules
- Batch all independent tool calls in one message
- Never re-read files already in context
- Compress old results instead of quoting verbatim
- Spawn subagents after 10+ heavy turns

---

## Model Selection

| Task | Model |
|------|-------|
| Lightweight agents, pair programming | Haiku 4.5 |
| Main development, orchestration (default) | Sonnet 4.6 |
| Complex architecture, deep reasoning | Opus 4.5 |

Switch: use `/model` or set in `~/.claude/settings.json`.

---

## New Project Checklist

```bash
# 1. Run setup from repo root
bash ~/path/to/claude/setup.sh

# 2. Index the codebase (one-time per project)
/gitnexus-init

# 3. Authenticate GitHub (one-time, optional but recommended)
gh auth login

# 4. Start building
/task "implement <first feature>"
```

---

## GitHub Auth

Without `gh auth login`:
- `/task` does all code work (branch, tests, implement, review)
- Outputs exact `git push` + `gh pr create` commands to run manually

With `gh auth login`:
- `/task` dispatches to Archon → auto push + PR creation
