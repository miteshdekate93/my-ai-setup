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

## Smart Defaults For Your Stack

Codex rules are tuned for React, Angular, C#/.NET, Azure, SQL Server, Oracle, and low-token agent work. Python/PyPI guidance is not used unless the repo is Python or you ask for it.

Simple prompts still trigger senior-agent behavior: git status, project rules, CONTEXT.md/lessons, L3 SOP recall, GitNexus impact for shared edits, rg/git grep reuse search, smallest safe change, and focused verification.

Reviewed-repo ideas folded in: minimal-safe ladder (Ponytail), CSS/native-first frontend state (prop-for-that), schema-first internal apps (nubase), architecture-as-code cue (LikeC4), and tool/memory reasoning (jcode/ReCall).
## What Gets Installed

| Path | What it does |
|------|-------------|
| `~/.codex/config.toml` | Model, sandbox mode, approval policy |
| `~/.codex/AGENTS.md` | Global instructions (all rules in one file) — Oracle drift-guard, scout+researcher pre-planning, worker discipline, fail-closed destructive ops, CONTEXT.md glossary |
| `~/.codex/skills/bmad-*` | Global BMAD Codex skills for planning, PRD/story work, quick dev, review, research, and documentation |
| `~/.codex/memory/L2/` | Entity fact memory: POLE+O facts about people, systems, events |
| `~/.codex/memory/L3/` | SOP memory directory (shared pattern with Claude setup) |
| GitNexus MCP | Code intelligence MCP server for impact analysis, context, query, and change detection |
| `~/.local/bin/codex-task` | Full pipeline orchestrator (equivalent to Claude's `/task`) |
| `~/.local/bin/codex-plan` | Planning only |
| `~/.local/bin/codex-tdd` | Add focused tests when requested or needed |
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

Equivalent to Claude Code's `/task`. Runs all phases autonomously:

-1. **Scout + Researcher** (parallel recon) — `context.md` + `external-reference.md`
1. **Branch** — `git checkout -b feat/<slug>`
2. **Plan** — numbered breakdown of changes + risks
3. **Verification plan** - identify focused checks; add tests only when requested or needed
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
# -> adds focused tests when requested or needed

codex-review
# → reviews git-changed files: names, errors, hardcoded values, edge cases

codex-security
# → scans git-changed files: secrets, injection, auth, input validation
```

---


## Optional Accelerators

These are used only when installed/configured. They are not required for normal Codex work.

| Tool | When to use | Codex rule |
|------|-------------|------------|
| Engram | Repeated project/domain work | Search indexed memory before planning; save compact findings after non-trivial tasks |
| Firecrawl | Current external docs/pages | Pull clean Markdown/structured evidence with source URLs; avoid raw page dumps |
| Nub | React/Angular/TypeScript command speed | Use `nub run`/`nubx` only when compatible with existing package scripts |
| no-mistakes | User asks to push/PR | Gate push through isolated validation when repo initialized |
| Herdr / Orca | Long parallel coding/review | Use separate terminals/worktrees; one writer per file |
| Rowboat pattern | Project knowledge | Keep memory local, Markdown, inspectable |

AirLLM skipped by default because it is Python/model-inference focused, not daily Codex coding setup for React/Angular/.NET/Azure/SQL/Oracle.

## How `codex-task` Works

### Stack detection (automatic)

| Detected file | Stack | Review focus |
|--------------|-------|-------------|
| `angular.json` / Angular package | Angular/TypeScript | Angular patterns, RxJS, templates |
| React/Next/Vite `package.json` | React/TypeScript | component state, hooks, rendering, accessibility |
| `*.sln` / `*.csproj` | C#/.NET | DI, config, logging, async, validation |
| `*.sql` / DB migration scripts | SQL Server / Oracle | transaction safety, parameterization, rollback |
| Azure files (`azure-pipelines.yml`, Bicep, appsettings) | Azure | config, deployment, secrets, environment safety |
| `package.json` fallback | Node/TypeScript | TS types, async errors |

### GitHub auth routing

| GitHub status | What happens |
|--------------|-------------|
| Authenticated | Full pipeline → outputs push + PR commands |
| Not authenticated | Full pipeline → outputs push + PR commands to run manually |

Either way, all code work (branch, tests, implement, review) runs locally first.

---

## Oracle — Drift Guard

For complex features (3+ phases), `codex-task` includes a built-in drift check:

After every 3 implementation phases, Codex pauses to verify:
1. Are current changes consistent with the original plan?
2. Were any architectural decisions made implicitly without approval?
3. Does the current trajectory contradict prior decisions?

**Key principle:** Consistency trumps novelty unless context strongly supports revision.
If drift detected: surface the contradiction, realign, then continue.

---

## CONTEXT.md — Project Shared Language

Create a `CONTEXT.md` in your project root (one-time, ~10 min):

```markdown
## Glossary
- **[Term]** — what it means in this specific codebase

## Architecture Decisions
- ADR-001: [Decision] — [Why] — [Date]
```

`codex-task` reads this before planning. Without it, Codex reasons from generic knowledge.
With it, Codex knows your domain, your patterns, and why architectural choices were made.

**Add to it whenever:** Claude/Codex makes a wrong assumption → that correction belongs in CONTEXT.md.

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
├── angular-form-validation.md
├── dotnet-api-validation.md
├── sqlserver-safe-migration.md
└── react-context-state.md
```

On the next similar task, the SOP is recalled automatically. No cold-start reasoning.

**Compound effect:** 10 similar tasks → 5x faster on the 10th.

L3 memory is compatible with Claude Code — SOPs written by one tool are readable by the other.

---

## Model Selection

Default model is `gpt-5.5`. Switch mid-session with `/model`.

| Task | Model | Switch |
|------|-------|--------|
| Simple fix, single file | gpt-4.1-mini | `/model gpt-4.1-mini` |
| Main development (default) | gpt-5.5 | — |
| Complex architecture, deep reasoning | o3 | `/model o3` |

Change default in `~/.codex/config.toml`:
```toml
model = "gpt-4.1-mini"   # cheaper for light work
```

---

## GitNexus MCP

Setup installs `gitnexus@1.6.5` globally when possible, then runs:

```bash
codex mcp add gitnexus -- gitnexus mcp
```

On Windows, PowerShell execution policy may block `npm.ps1` or `npx.ps1`; use `npm.cmd` and `npx.cmd`.
If package-manager install is blocked by corporate policy, install GitNexus through the approved internal software channel, then rerun setup.

---

## BMAD Global Skills

Setup copies bundled BMAD skills from `codex/skills/bmad-*` into:

```bash
~/.codex/skills/bmad-*
```

These become available to new Codex sessions as global skills.

Use BMAD when work needs structured discovery, planning, story execution, review, or documentation:

```text
Use bmad-quick-dev for this bug fix. Confirm root cause before edits. Keep change scoped.
```

```text
Use bmad-dev-story for this story file. Follow acceptance criteria and update sprint status only if asked.
```

```text
Use bmad-code-review. Review changed files for bugs, regressions, security, performance, and missing validation.
```

Most useful daily BMAD skills:

- `bmad-quick-dev` - bug fixes and small implementation work
- `bmad-dev-story` - prepared story implementation
- `bmad-code-review` - structured code review
- `bmad-correct-course` - scope change or plan drift
- `bmad-create-story` - turn requirements into implementable story
- `bmad-technical-research` - research current technical approach
- `bmad-generate-project-context` - create project context docs

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
- Coding style (immutability, linear control flow, regenerability, file size, error handling)
- Design patterns (Repository, Vertical Slice Architecture, API response envelope)
- Development workflow (research → plan → TDD → review → commit)
- Git commit format (conventional commits)
- Testing requirements (80% coverage, TDD mandatory)
- Security checklist
- Model selection + reasoning strategy guide
- Context budget rules
- Three-tier memory: L2 entity facts (POLE+O) + L3 SOP crystallization
- Oracle drift-guard (consistency check after every 3 phases)
- Scout + Researcher pre-planning recon pattern
- Worker discipline (smallest correct change, no placeholders, escalate unapproved scope)
- Fail-closed for destructive operations (deny if context missing/ambiguous)
- CONTEXT.md project glossary pattern
- L2 memory staleness (Last-verified + Expires fields, flag facts >6 months old)

---

## New Project Checklist

```bash
# 1. Run setup from repo root
bash ~/path/to/codex/setup.sh

# 2. Authenticate GitHub (one-time, optional but recommended)
gh auth login

# 3. Start building
codex-task "implement <first feature>"

# 4. Create CONTEXT.md (one-time — 10 min)
# Domain terms + key architectural decisions
# codex-task reads this before every plan
```

---

## GitHub Auth

Without `gh auth login`:
- `codex-task` does all code work (branch, tests, implement, review)
- Outputs exact `git push` + `gh pr create` commands to run manually

With `gh auth login`:
- Same workflow, but the git commands at the end can be run in one copy-paste
