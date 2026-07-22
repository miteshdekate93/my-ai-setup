#!/usr/bin/env bash
set -euo pipefail

# OpenAI Codex CLI Setup Script
# Run this on any new Mac/Linux to restore your full Codex configuration.
# Usage: bash codex/setup.sh

echo "Setting up OpenAI Codex CLI configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Install Codex CLI if missing ──────────────────────────────────────────────
if ! command -v codex &>/dev/null; then
  echo "Installing Codex CLI..."
  npm install -g @openai/codex
  echo "Codex CLI installed."
else
  echo "Codex CLI already installed: $(codex --version 2>/dev/null || echo 'version unknown')"
fi

# ── ~/.codex/config.toml ─────────────────────────────────────────────────────
mkdir -p "$HOME/.codex"
cat > "$HOME/.codex/config.toml" << 'EOF'
# OpenAI Codex CLI Configuration

# Default model — gpt-4.1 is best for coding tasks
model = "gpt-5.5"

# Sandbox: "danger-full-access" lets Codex read/write/run anything (like Claude Code)
# Options: "read-only" | "workspace-write" | "danger-full-access"
sandbox = "danger-full-access"

# Approval: "never" = fully autonomous (like Claude Code auto-approve)
# Options: "untrusted" | "on-request" | "never"
ask_for_approval = "never"

# Parallel tool calls for speed
supports_parallel_tool_calls = true

# Max instruction file size (32 KiB default)
project_doc_max_bytes = 65536

[desktop]
default-service-tier = "priority"
EOF

# Install GitNexus and wire it into Codex MCP when available.
if ! command -v gitnexus &>/dev/null; then
  echo "Installing GitNexus CLI..."
  npm install -g gitnexus@1.6.5 || echo "Warning: GitNexus install failed; run: npm install -g gitnexus@1.6.5"
fi

if command -v codex &>/dev/null && command -v gitnexus &>/dev/null; then
  if ! codex mcp list 2>/dev/null | grep -qE '(^|[[:space:]])gitnexus([[:space:]]|$)'; then
    echo "Adding GitNexus MCP server to Codex..."
    codex mcp add gitnexus -- "$(command -v gitnexus)" mcp || echo "Warning: GitNexus MCP setup failed; run: codex mcp add gitnexus -- gitnexus mcp"
  else
    echo "GitNexus MCP already configured."
  fi
else
  echo "Warning: GitNexus MCP not configured. Install gitnexus and run: codex mcp add gitnexus -- gitnexus mcp"
fi

# ── ~/.codex/AGENTS.md — global instructions (equivalent to ~/.claude/rules/) ─
cat > "$HOME/.codex/AGENTS.md" << 'EOF'
# Global Codex Instructions

These rules apply to every Codex session across all projects.

---

# Caveman Mode — Always Active

Respond terse like smart caveman. All technical substance stay. Only fluff die.

Drop: articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries
(sure/certainly/of course/happy to), hedging. Fragments OK. Short synonyms (big not extensive,
fix not "implement a solution for"). Technical terms exact. Code blocks unchanged. Errors quoted exact.

Pattern: `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by..."
Yes: "Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:"

## Hedge Reducer (Always Active)

Strip these from all prose — never say them:

| Drop | Replace with |
|------|-------------|
| "I think" / "I believe" / "I feel" | state directly |
| "maybe" / "perhaps" / "possibly" / "probably" | drop or assert |
| "it seems" / "it appears" / "it looks like" | state the fact |
| "I'd suggest" / "you might want to" / "consider" | imperative form |
| "certainly" / "of course" / "absolutely" / "definitely" | drop |
| "just" / "simply" / "basically" / "essentially" | drop |
| "I'm happy to" / "I'd be glad to" / "Let me help you" | drop preamble |
| "Great question" / "Excellent point" / "Good idea" | drop entirely |

## Intensity

Default: **full** (drop articles, fragments OK, short synonyms).

Tell Codex to switch: "caveman lite" | "caveman full" | "caveman ultra"
Tell Codex to stop: "normal mode"

| Level | Behavior |
|-------|----------|
| lite | No filler/hedging. Keep articles + full sentences. Tight but readable. |
| full | Drop articles, fragments OK, short synonyms. Classic caveman. |
| ultra | Abbreviate (DB/auth/config/req/res/fn), strip conjunctions, arrows for causality (X → Y). |

## Auto-Clarity

Drop caveman for: security warnings, irreversible action confirmations, multi-step sequences
where fragment order risks misread. Resume after.

Code/commits/PRs: write normal. Only prose is compressed.

---

# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:
- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors

## Input Validation

ALWAYS validate at system boundaries:
- Validate all user input before processing
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)

## Linear Control Flow

Prefer linear, top-to-bottom flow in functions:
- Use early returns instead of deeply nested conditionals
- Flatten async chains with async/await — no callbacks inside callbacks
- Side effects explicit and visible, not hidden inside branches
- One level of indirection per function

## Regenerability

Files should be independently rewritable without breaking other modules:
- Avoid hidden coupling — changes to one module shouldn't cascade to 5 others
- Define clear interfaces between modules
- No circular dependencies
- If a file can't be rewritten in isolation, extract its public contract first

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
- [ ] Linear control flow (early returns over nesting)
- [ ] No circular dependencies

---

# Smart Agent Defaults

Even simple prompts run as senior-agent work:
1. Classify request: question, bug, feature, refactor, review, deploy, data/DB.
2. Check git status before edits.
3. Read project instructions, CONTEXT.md, tasks/lessons.md, and relevant L3 SOP memory when present.
4. Use GitNexus context/impact before shared symbol, API route, DB, or cross-module edits.
5. Search existing code with rg/git grep before creating helpers, components, services, SQL, or Azure scripts.
6. Use smallest safe change. Prefer reuse/native platform/config over new abstraction or dependency.
7. Run focused existing checks. Add tests only when user asks, repo pattern expects it, or bug/high-risk behavior needs regression coverage.
8. Do not commit or push unless explicitly asked.

---

# Technology Focus

Default stack: React, Angular, TypeScript, C#/.NET, ASP.NET Core, Azure DevOps/IIS/App Services/Key Vault/App Configuration, SQL Server, Oracle, and Claude/Codex automation.

Do not propose Python implementations, PyPI packages, or Python scripts unless the repo is already Python or user explicitly asks. For automation prefer PowerShell, Node/TypeScript, C#/.NET CLI, SQL, Azure CLI, or Azure PowerShell.

Frontend default: use native HTML/CSS/browser APIs, Angular/React built-in patterns, existing component libraries, and CSS/container queries/custom properties before JavaScript render loops or new packages.

Backend default: follow existing .NET solution layout, dependency injection, configuration, logging, EF/Dapper/repository patterns already in repo, and minimal scoped changes.

DB default: use parameterized SQL, transaction safety, rollback notes, least-privilege grants, repo migration/script pattern, and PII/secrets protection for SQL Server and Oracle.

Azure default: use existing pipeline, appsettings, Key Vault/App Configuration, IaC, and deployment scripts before introducing new tooling.

---

# Minimal Safe Ladder

Before coding: prove need, reuse existing code, use framework/platform, use installed dependency, then add smallest new code.
Never simplify away validation, authorization, PII/secret safety, SQL injection protection, error handling, accessibility, auditability, or requested behavior.

---

# Tool And Token Discipline

- Start with GitNexus, rg, git grep, and targeted file reads; avoid whole-repo or whole-file reads unless needed.
- Prefer llms.txt, official docs, vendor docs, and compact project docs when available.
- Batch independent reads/searches.
- Use tool evidence before root-cause or impact claims.
- For architecture-heavy work, check existing ADRs/diagrams and ask whether LikeC4/C4/docs should be updated.
- For CRUD/internal admin apps, prefer schema-first patterns and existing generated/configured UI paths before hand-building screens.

# Agent Memory And External Context

Use memory and external context only when it improves accuracy or reduces repeated reasoning:
- Local Markdown remains source of truth: `CONTEXT.md`, `tasks/lessons.md`, `~/.codex/memory/L2/`, `~/.codex/memory/L3/`.
- If Engram MCP/tools exist, run memory search/context at task start and save compact findings at task end. Use it as indexed recall, not hidden authority.
- If Firecrawl/MCP/tools exist and current web docs are needed, prefer clean Markdown/structured extraction over raw browser copy. Store source URL + date in notes.
- For external docs, prefer official/vendor docs first; use broader web only when vendor docs are incomplete.
- Never paste large scraped output into prompt. Extract only exact API, command, version, error, or decision evidence needed.

# Agent Fleet And Push Gate

Use fleet tools only for work that benefits from parallelism:
- Herdr/Orca pattern: run independent agents in separate terminals/worktrees, compare outputs, merge only winner-quality changes.
- Keep one writer per file/worktree. Parallel readers/reviewers OK; parallel writers need isolated branches/worktrees.
- Use no-mistakes-style gate before push when available and user asks to push: review, tests, docs/lint, PR body, CI follow-up before branch reaches origin.
- For simple <=2-file edits, stay inline. Fleet orchestration costs more than it saves.

# Node And Frontend Speed

For React/Angular/TypeScript repos:
- Use repo package manager and scripts first (`npm`, `pnpm`, `yarn`, Nx, Angular CLI, Vite, MSBuild integration).
- If Nub is installed, use it only as compatible acceleration (`nub run`, `nubx`, `nub watch`) after confirming repo scripts still behave the same.
- Do not replace project runtime, lockfile, or CI toolchain without explicit approval.

---
# Development Workflow

## Feature Implementation Workflow

-1. **Scout + Researcher** _(parallel recon — skip for trivial/single-file fixes)_
   - Scout: read relevant files, existing patterns, test coverage → write to `context.md`
   - Researcher: check library docs, API behavior, breaking changes → write to `external-reference.md`
   - Plan uses both artifacts as input — eliminates cold-start planning

0. **Research & Reuse** _(mandatory before any new implementation)_

   **Retrieval-led reasoning:** Always read relevant docs and code BEFORE implementing. Pre-training knowledge is the fallback, not the primary source. Cost of retrieval is near-zero; cost of wrong assumptions is high.

   **Three-Layer Knowledge Search:**
   - **Layer 1 — Tried and true:** Standard patterns you already know. Check anyway — cost is near-zero. This is your baseline.
   - **Layer 2 — New and popular:** Current docs, blog posts, ecosystem trends. Search but scrutinize — the crowd can be wrong.
   - **Layer 3 — First principles:** Original reasoning about the specific problem. Most valuable. The Eureka Moment: understanding what everyone does and WHY, then finding why the conventional approach is wrong for this case.

   **Concrete steps:**
   - Search local repo first with rg/git grep, then use GitHub search only when adopting a library or proven skeleton helps
   - Use vendor docs to confirm API behavior before implementing
   - Search npm, NuGet, Microsoft/Azure docs, Oracle docs, vendor docs, and existing repo code before writing utility code. Use PyPI/crates.io only when the repo is explicitly Python/Rust or the user asks.
   - Prefer adopting/porting a proven approach over writing net-new code

1. **Plan First**
   - Break down into phases
   - Identify dependencies and risks
   - Write numbered plan before coding
   - Check `CONTEXT.md` for domain terms and ADRs before planning

2. **Testing And Verification**
   - Run focused existing checks by default
   - Add tests only when user asks, repo pattern expects it, or bug/high-risk behavior needs regression coverage
   - Keep the existing test framework and naming pattern
   - Report any verification gap clearly

3. **Code Review**
   - Check unclear names, missing error handling, hardcoded values
   - Address CRITICAL and HIGH issues before continuing
   - Max 3 review rounds; stop early if no blockers

4. **Commit & Push**
   - Conventional commits: feat/fix/refactor/docs/test/chore/perf/ci
   - Detailed commit messages

---

# Git Workflow

## Commit Message Format
```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

## Pull Request Workflow

1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

---

# Testing And Verification

Default: run existing relevant checks. Do not create new unit, integration, or E2E tests unless the user asks, the repository already has a matching pattern for the touched behavior, or a bug/high-risk change needs regression coverage.

When adding tests, use the repo's existing framework and naming style, keep tests focused on changed behavior, cover the failing case first for bugs, and avoid broad test rewrites.

When not adding tests, run the best available focused build/test/smoke command and report the verification gap.

---

# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on all endpoints
- [ ] Error messages don't leak sensitive data

## Secret Management

- NEVER hardcode secrets in source code
- ALWAYS use environment variables or a secret manager
- Validate that required secrets are present at startup
- Rotate any secrets that may have been exposed

---

# Performance — Model Selection

**gpt-4.1-mini** (fast, cost-efficient):
- Simple bug fixes, single-file edits
- Documentation updates
- Config changes

**gpt-4.1** (best coding model — default):
- Main development work
- Multi-file changes
- Complex coding tasks

**o3** (deepest reasoning):
- Complex architectural decisions
- Debugging hard-to-reproduce issues
- Research and analysis

Switch mid-session: `/model gpt-4.1-mini` or `/model o3`

## Reasoning Strategy

Combine model selection with structured thinking for complex tasks:

**gpt-4.1 + explicit plan prompt:**
- Task has 3+ interdependent steps
- Multi-file changes with dependencies
- Debugging a known but complex issue

**o3 (switch with `/model o3`):**
- Root cause unclear after first analysis
- Architecture decisions with competing trade-offs
- Algorithm correctness must be verified
- Estimating impact of a large refactor

**Pattern for complex tasks:**
1. `codex-plan "task"` with gpt-4.1 → get numbered breakdown
2. Switch to o3 for the hardest decision: `/model o3`
3. Switch back for implementation: `/model gpt-4.1`

Never use o3 for simple fixes — cost is 10x gpt-4.1-mini.

---

# Context Budget Management

- Start with GitNexus, rg, git grep, and targeted file reads.
- Never re-read a file already read in this session.
- Read only needed lines before full files.
- Prefer llms.txt, official docs, vendor docs, and compact project docs when available.
- Batch independent operations together.
- Never re-run the same command twice unless state changed.
- Summarize findings; never paste tool output verbatim into prose.
- Use L3 SOP memory before cold reasoning on repeat tasks.

---

# Memory Crystallization — Three-Tier Architecture

Three memory tiers: entity facts (L2), reusable SOPs (L3). L1 = session context (conversation only).

| Tier | What | Location |
|------|------|----------|
| L2 | Entity facts: systems, decisions, people, services | `~/.codex/memory/L2/` |
| L3 | Skill SOPs: proven task patterns per stack/domain | `~/.codex/memory/L3/` |

## L2 Entity Memory (POLE+O)

Save durable facts about project entities:
- **P**erson — roles, preferences ("Alice owns auth module")
- **O**bject — systems, configs ("payments uses Stripe v3")
- **L**ocation — repos, environments, paths
- **E**vent — decisions, incidents, migrations
- **O**rganization — teams, external services

Save to `~/.codex/memory/L2/<project>-<entity-type>-<slug>.md`.
Update (don't duplicate) when facts change.

## L3 SOP Memory — At Task Start

```bash
ls ~/.codex/memory/L3/ 2>/dev/null | grep -i "<keyword>"
```

If SOP found: read it, use as starting pattern, skip cold reasoning.

## L3 SOP Memory — At Task End

After completing any non-trivial task (3+ implementation steps):
1. Distill what worked into a reusable SOP
2. Save to `~/.codex/memory/L3/<stack>-<domain>-<slug>.md`
3. Keep short — steps + gotchas only, under 30 lines

## Memory Type Taxonomy

When saving L3 memories, classify by type:
- **pattern** — reusable code/architectural pattern
- **preference** — user or project preference discovered during work
- **architecture** — system design decision with rationale
- **bug** — bug found + root cause + fix (include importance score)
- **workflow** — process that worked well for this stack/domain
- **fact** — durable fact about the codebase, API, or system

## Crystal Lifecycle (End of Multi-Step Tasks)

After any task with 3+ implementation steps, crystallize into a Crystal before the SOP:

```
Crystal:
  narrative: "1-2 sentence summary of what was accomplished"
  keyOutcomes:
    - "Decision or change made"
    - "Pattern established"
  filesAffected:
    - "path/to/file"
  lessons:
    - "Reusable insight with confidence: high/medium/low"
```

Crystals feed into L3 SOPs. Lessons with confidence:high get saved as standalone L3 entries.

## Importance Scale

When noting why a memory matters (1-10):
- 1-3: Routine reads, minor lookups
- 4-6: File edits, command runs, feature additions
- 7-9: Architectural decisions, API contracts, breaking changes
- 10: Critical system changes, security fixes, data migrations

## SOP Format (L3)

```markdown
# SOP: <domain> — <what this covers>
Stack: <language/framework>
Last used: <YYYY-MM-DD>

## Steps
1. ...

## Gotchas
- ...
```

## Entity Fact Format (L2)

```markdown
# Entity: <name>
Type: Person | Object | Location | Event | Organization
Project: <project or "global">
Observed: <YYYY-MM-DD>
Last-verified: <YYYY-MM-DD>
Expires: <YYYY-MM-DD or "never">

## Facts
- ...

## Staleness Rules

- Always check `Last-verified` before acting on a L2 fact
- Facts >6 months old without re-verification: flag as POSSIBLY STALE, verify before using
- When a fact is confirmed still true: update `Last-verified` date
- When a fact changes: update in-place (don't duplicate)
- When a fact expires: delete the file, don't leave stale data
```

---

# Common Patterns

## Repository Pattern

Encapsulate data access behind a consistent interface:
- Define standard operations: findAll, findById, create, update, delete
- Business logic depends on the abstract interface, not the storage mechanism
- Enables easy swapping of data sources and simplifies testing with mocks

## Vertical Slice Architecture (VSA)

Organize code by feature slice, not by technical layer:
- Each feature lives in one folder: request + handler + response + tests
- ❌ Layered: `controllers/UserController`, `services/UserService`, `repos/UserRepo`
- ✅ Sliced: `features/CreateUser/handler`, `features/CreateUser/request`, `features/CreateUser/tests`
- Benefits: changes to one feature touch one folder; no cross-layer coupling
- Use for APIs with distinct, high-cohesion operations (CQRS-friendly)

## API Response Format

Use a consistent envelope for all API responses:
- Include a success/status indicator
- Include the data payload (nullable on error)
- Include an error message field (nullable on success)
- Include metadata for paginated responses (total, page, limit)

---

# Boil the Lake — Completeness Ethos

When AI makes the marginal cost of completeness near-zero, do the complete thing every time.

## Lakes vs Oceans

- **Lake** = boilable: full changed behavior, all relevant edge cases, focused verification. Do it.
- **Ocean** = not boilable: rewriting an entire system unprompted. Flag it, don't do it.

## Always Boil These Lakes

- Verify all changed behavior; add tests only when user asks, repo pattern expects it, or risk justifies regression coverage
- Handle all error cases, not just the obvious one
- Complete the feature, don't leave stubs
- Fix the root cause, not just the symptom

## Anti-Patterns

- "Choose B — it's 90% there with less code" → if A is correct, do A
- "No verification needed" -> run focused checks or explain the gap
- "This would take 2 weeks" → say "2 weeks human / ~1 hour AI-assisted"

## User Sovereignty

Models recommend. Humans decide. Two models agreeing is a strong signal, not a mandate.

- Always present recommendation + reasoning + what context you might be missing
- When you disagree with user's direction: state it once, clearly, then follow their decision
- Never act on a direction change without asking first — even if confident
- The user always has context models lack

---

# Debugging — Iron Law

No fix without confirmed root cause. Four phases, mandatory in order.

## Phase 1 — Investigate
- Reproduce the bug reliably
- Gather all evidence: logs, stack traces, failing tests
- Map what IS happening vs what SHOULD happen
- Do not form hypotheses yet

## Phase 2 — Analyze
- Study the evidence
- Trace the execution path
- Identify where behavior diverges from expectation

## Phase 3 — Hypothesize
- Form ONE specific hypothesis about root cause
- State it: "I believe X causes Y because Z"
- If multiple hypotheses, rank by likelihood and test top one

## Phase 4 — Implement
- Fix ONLY what the hypothesis points to
- Add a regression test only when user asks, repo pattern exists, or risk justifies it; otherwise document focused verification
- Verify the fix resolves the original reproduction case

> Never implement a fix before completing Phase 3. No root cause = go back to Phase 1.

---

# Workflow Orchestration

## Plan Mode Default
- Plan ANY non-trivial task (3+ steps or architectural decisions) before coding
- If something goes sideways, STOP and re-plan — don't keep pushing
- Write detailed specs upfront to reduce ambiguity

## Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user

## Verification Before Done
- Never mark a task complete without proving it works
- Run focused checks, inspect logs when relevant, demonstrate correctness
- Ask yourself: "Would a staff engineer approve this?"

## Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake

## Oracle Drift-Guard (Long Features)
After every 3 implementation phases, pause and check:
1. Are current changes consistent with the original plan?
2. Have any architectural decisions been made implicitly without approval?
3. Does current trajectory contradict prior decisions?

**Consistency trumps novelty unless context strongly supports revision.**
If drift found: stop, surface contradiction, realign before continuing.

## Worker Discipline
When implementing:
- Smallest correct change — don't rewrite what isn't broken
- Follow existing patterns — no speculative refactors
- No placeholder code — implement fully or escalate
- No silent scope expansion — escalate unapproved architectural decisions
- No success summaries without corresponding edits

## Fail-Closed for Destructive Operations
If context is missing or ambiguous on ANY destructive operation (delete, drop, truncate, force-push, overwrite): DENY and ask.
"I think this is safe" is not good enough — confirm explicitly before executing.

## CONTEXT.md — Project Shared Language
Every project should have a `CONTEXT.md` with domain terms + Architecture Decision Records.
Read it before planning any complex feature. Update it when new ADRs are made.
Format: glossary of domain terms + numbered ADR list (decision + rationale + date).
EOF

# ── AGENTS.md in current directory (project instructions) ────────────────────
cat > "$PWD/AGENTS.md" << 'EOF'
# Project Instructions for Codex

## Workflow Orchestration

### 1. Plan Mode Default
- Plan ANY non-trivial task (3+ steps or architectural decisions) before coding
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use planning for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Autonomous Execution
- For bug reports: just fix them. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them.
- Go fix failing CI tests without being told how.

### 3. Self-Improvement Loop
- After ANY correction: update `tasks/lessons.md` with the pattern
- Write rules to prevent the same mistake
- Review lessons at session start for relevant context

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Run focused checks, inspect logs when relevant, demonstrate correctness
- Ask yourself: "Would a staff engineer approve this?"

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- Skip for simple, obvious fixes — don't over-engineer

---

# Code Style: Readable & Explainable

**Principle:** Simple code > Clever code. You must be able to explain it in 2 minutes.

## Functions: Short & Clear
- **Max 20 lines per function** — else break it into smaller ones
- **One responsibility** — if it does A and B, split it
- **Clear names** — not `u`, `d`, `x` — use `user`, `document`, `count`

```typescript
// ✅ GOOD
function canUserDeleteDocument(user: User, document: Document): boolean {
  const isDocumentOwner = user.id === document.ownerId;
  const isAdmin = user.role === 'admin';
  return isDocumentOwner || isAdmin;
}

// ❌ AVOID
function canDel(u: User, d: Document) {
  return u.id === d.ownerId ? true : u.role === 'admin' ? true : false;
}
```

## Variable Names: Explicit, Readable
```typescript
// ✅ GOOD
const userHasAccessToSharedDocument = user.sharedDocuments.includes(docId);
const maxLoginAttemptsBeforeLockout = 5;

// ❌ AVOID
const hasAccess = u.docs.includes(d);
const max = 5;
```

## Comments: Explain WHY, Not WHAT
```typescript
// ✅ GOOD — business rule, not obvious
const MAX_LOGIN_ATTEMPTS = 5;  // Security: Prevent brute-force attacks

// ❌ AVOID — repeats code
const user = getUserById(id);  // Get user by ID
```

---

# Codex Commands

Use the helper scripts installed by setup.sh:

## Pipeline
- `codex-task "implement X"` — Full pipeline: plan → TDD → implement → review → security → SOP
- `codex-plan "feature X"` — Planning only: breakdown + risks
- `codex-tdd "test X"` - add focused tests when explicitly requested
- `codex-review` — Code review on changed files
- `codex-security` — Security scan on changed files

## Daily Workflow

### New Feature
```
1. codex-plan "Build feature"      → Clear breakdown
2. Run focused checks              -> Verify touched behavior
3. codex-task "implement X"        → Full pipeline
4. codex-review                    → Catch issues early
5. codex-security (if needed)      → Verify safety
```

### Bug Fix
```
1. codex-task "fix bug in X"       → Classify → branch → plan → test → fix → review
```

### When Stuck
```
codex-task "fix build error: <error>"   → Build fix
codex-review                            → Logic error or unclear code
cat tasks/lessons.md                    → Pattern you've seen before?
```

---

# Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Track Progress**: Mark items complete as you go
3. **Capture Lessons**: Update `tasks/lessons.md` after corrections

---

# Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary.
- **Readable > Clever**: Code anyone can understand and maintain.
- **Explainable**: If you can't explain it in 2 minutes, simplify it.
EOF

# ── tasks/ in current directory ───────────────────────────────────────────────
mkdir -p "$PWD/tasks"

cat > "$PWD/tasks/todo.md" << 'EOF'
# Todo

## Current Tasks

- [ ] Add tasks here

## Completed

EOF

cat > "$PWD/tasks/lessons.md" << 'EOF'
# Lessons Learned

Track patterns and corrections here to avoid repeating mistakes.

## Format

**Lesson:** What went wrong or what worked well
**Why:** Root cause or reason
**Rule:** What to do differently next time

---

EOF

# ── L2 + L3 memory directories ────────────────────────────────────────────────
mkdir -p "$HOME/.codex/memory/L2"
mkdir -p "$HOME/.codex/memory/L3"
echo "Memory directories created: ~/.codex/memory/L2/ and ~/.codex/memory/L3/"


# Optional agent accelerators (detect only; no surprise installs)
mkdir -p "$HOME/.codex/tools"
cat > "$HOME/.codex/tools/agent-accelerators.md" << 'EOF'
# Optional Agent Accelerators

These tools are not required. Use them only when installed/configured and useful for the current task.

| Tool | Use | Codex behavior |
|------|-----|----------------|
| Engram | Indexed persistent memory over SQLite/FTS5 via MCP | Search at task start, save compact task learnings at end |
| Firecrawl | LLM-ready web search/scrape/MCP | Pull current docs/pages as clean Markdown/structured evidence |
| Nub | Faster Node/TypeScript commands | Use `nub run`/`nubx` only when compatible with repo scripts |
| no-mistakes | Pre-push validation gate | Use before push/PR when user asks to push and repo is initialized |
| Herdr | Terminal agent multiplexer | Coordinate long-running agent panes without losing state |
| Orca | Parallel agent worktrees | Fan out complex work into isolated worktrees and compare results |
| Rowboat pattern | Local-first knowledge graph | Keep project memory inspectable in Markdown |

Skipped by default: AirLLM. It is model-inference/Python-focused, not daily React/Angular/.NET/Azure/SQL/Oracle coding setup.
EOF

if command -v engram >/dev/null 2>&1; then
  echo "Engram detected. To wire Codex memory MCP, run once: engram setup codex"
else
  echo "Engram not installed (optional indexed memory)."
fi
for tool in firecrawl nub no-mistakes herdr orca; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "Optional accelerator detected: $tool"
  fi
done

# Global BMAD Codex skills
BMAD_SOURCE="$SCRIPT_DIR/skills"
BMAD_TARGET="$HOME/.codex/skills"
mkdir -p "$BMAD_TARGET"
if [ -d "$BMAD_SOURCE" ]; then
  BMAD_COUNT=0
  while IFS= read -r skill_dir; do
    skill_name="$(basename "$skill_dir")"
    case "$skill_name" in
      bmad-*) ;;
      *) echo "Unsafe BMAD skill name: $skill_name"; exit 1 ;;
    esac
    rm -rf "$BMAD_TARGET/$skill_name"
    cp -R "$skill_dir" "$BMAD_TARGET/"
    BMAD_COUNT=$((BMAD_COUNT + 1))
  done < <(find "$BMAD_SOURCE" -mindepth 1 -maxdepth 1 -type d -name 'bmad-*' | sort)
  echo "BMAD Codex skills installed globally: $BMAD_COUNT skills -> $BMAD_TARGET"
else
  echo "Warning: BMAD skill source not found: $BMAD_SOURCE"
fi

# ── codex-task — full pipeline orchestrator (equivalent to /task in Claude) ───
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/codex-task" << 'SCRIPT'
#!/usr/bin/env bash
# codex-task — full dev pipeline orchestrator for Codex CLI
# Equivalent to /task in Claude Code.
# Usage: codex-task "implement dark mode in the settings page"

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: codex-task \"<what to implement, fix, or build>\""
  exit 1
fi

TASK="$*"
STACK="unknown"

# Detect project stack (focused daily stack)
if [ -f "angular.json" ] || { [ -f "package.json" ] && grep -qi angular package.json 2>/dev/null; }; then
  STACK="Angular/TypeScript"
elif [ -f "package.json" ] && grep -Eqi 'react|next|vite' package.json 2>/dev/null; then
  STACK="React/TypeScript"
elif find . -maxdepth 3 \( -name "*.sln" -o -name "*.csproj" \) -print -quit 2>/dev/null | grep -q .; then
  STACK="C#/.NET"
elif find . -maxdepth 3 -name "*.sql" -print -quit 2>/dev/null | grep -q .; then
  STACK="SQL/Database"
elif [ -f "package.json" ] || [ -f "bun.lockb" ] || [ -f "deno.json" ]; then
  STACK="Node/TypeScript"
fi

# Check GitHub auth
GH_STATUS="GH_NOT_AUTHED"
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  GH_STATUS="GH_AUTHED"
fi

# Search L3 memory and load SOP content if found
KEYWORD=$(echo "$TASK" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
SOP_BLOCK=""
if ls ~/.codex/memory/L3/ 2>/dev/null | grep -qi "$KEYWORD"; then
  SOP_FILE=$(ls ~/.codex/memory/L3/ | grep -i "$KEYWORD" | head -1)
  SOP_CONTENT=$(cat "$HOME/.codex/memory/L3/$SOP_FILE" 2>/dev/null || echo "")
  if [ -n "$SOP_CONTENT" ]; then
    SOP_BLOCK="## Recalled SOP from memory: $SOP_FILE

$SOP_CONTENT

Use the steps and gotchas above as your starting pattern. Skip cold reasoning for anything already documented there.
"
  fi
fi

PIPELINE_PROMPT="Execute the full development pipeline autonomously for this task: $TASK

Stack detected: $STACK
GitHub auth: $GH_STATUS
${SOP_BLOCK}

Follow ALL phases below without asking for confirmation between them:

## Always-On Smart Context
- Run git status first and protect user changes.
- Read AGENTS.md/CONTEXT.md/tasks/lessons.md when present.
- Recall matching L3 SOP memory before cold reasoning.
- Use GitNexus context/impact before shared symbols, APIs, DB scripts, or cross-module edits.
- Search existing code with rg/git grep before creating helpers/components/services.
- Prefer React, Angular, C#/.NET, Azure, SQL Server, and Oracle patterns. Do not propose Python unless this repo is Python or user asks.
- Use native/platform/CSS/framework features before new dependencies.
- If Engram memory tools are available, search before planning and save compact task learning at the end.
- If Firecrawl tools are available and current web docs are needed, retrieve only clean Markdown/structured evidence with source URLs.
- If Nub is available in React/Angular/TypeScript repos, use it only as compatible command acceleration after confirming repo scripts.
- If Herdr/Orca/no-mistakes are available, use them for long parallel work or push-gated PRs only when the task warrants it.
- If you see a better improvement outside scope, mention it and continue requested scope unless user approves expansion.

## Phase 1 — Branch
Create a local git branch:
  git checkout -b <type>/<short-slug>
Type: feat/fix/refactor/docs/chore based on the task.

## Phase 2 — Plan
Break down the task:
- What files change and why
- Before vs after behavior
- How to verify correctness
- Risks and dependencies
Output a numbered list. This is the plan — proceed immediately.

## Phase 3 - Verification Plan
Identify focused existing checks for the touched area. Add tests only when user asked, repo pattern expects it, or bug/high-risk behavior needs regression coverage. For bugs, prefer one regression test when existing test pattern is clear.

## Phase 4 — Implement (GREEN)
Write minimal scoped code for the verified behavior.
Rules:
- Functions ≤20 lines, one responsibility
- No mutation — new objects, never modify in-place
- Explicit error handling — never swallow silently
- No hardcoded values — constants or config
Run focused build/test/smoke checks before continuing.

## Phase 5 — Code Review
Check all changed files for:
- Unclear names, missing error handling, hardcoded values
- Logic errors, missing edge cases, over-engineering
Fix CRITICAL/HIGH issues. Report MEDIUM but continue.

## Phase 6 — Security (conditional)
Skip for: pure logic, UI styling, config, renaming.
Run for: auth, user input, APIs, DB, file I/O, secrets.
Verify:
- No hardcoded secrets
- Inputs validated
- SQL parameterized
- No data leaks in logs/errors

## Phase 7 — Crystallize SOP
After non-trivial tasks (3+ implementation steps):
Save to ~/.codex/memory/L3/<stack>-<domain>-<slug>.md
Format: title, stack, date, numbered steps, gotchas. Under 30 lines.
Skip for: one-liners, config tweaks, pure Q&A.

## Phase 8 — Done + Git Commands
Output a summary, then these commands:

  # Review what changed:
  git diff main

  # Commit:
  git add -A
  git commit -m \"<type>: <short description>\"

  # Push (needs GitHub auth or git credentials):
  git push -u origin <branch-name>

  # Create PR (needs: gh auth login):
  gh pr create --title \"<title>\" --body \"<summary of changes>\"

  # If not authenticated yet:
  gh auth login

Always output these commands even if GitHub is authenticated.
Caveman compression active — responses terse but technically precise."

exec codex "$PIPELINE_PROMPT"
SCRIPT

chmod +x "$HOME/.local/bin/codex-task"
echo "codex-task installed: ~/.local/bin/codex-task"

# ── codex-plan — planning only ────────────────────────────────────────────────
cat > "$HOME/.local/bin/codex-plan" << 'SCRIPT'
#!/usr/bin/env bash
# codex-plan — planning phase only (equivalent to /plan in Claude Code)
# Usage: codex-plan "implement dark mode in the settings page"
set -euo pipefail
if [ $# -eq 0 ]; then
  echo "Usage: codex-plan \"<feature to plan>\""
  exit 1
fi
exec codex "Plan this task. Output a numbered breakdown:
- What files change and why
- Before vs after behavior
- How to verify correctness
- Risks and dependencies
- Estimated complexity
Be terse. No implementation yet — just the plan.

Task: $*"
SCRIPT
chmod +x "$HOME/.local/bin/codex-plan"

# ── codex-tdd — TDD phase only ────────────────────────────────────────────────
cat > "$HOME/.local/bin/codex-tdd" << 'SCRIPT'
#!/usr/bin/env bash
# codex-tdd — add focused tests when requested (equivalent to /tdd in Claude Code)
# Usage: codex-tdd "user authentication logic"
set -euo pipefail
if [ $# -eq 0 ]; then
  echo "Usage: codex-tdd \"<logic to test>\""
  exit 1
fi
exec codex "Write failing tests (RED phase of TDD) for this logic: $*

Rules:
- Tests must FAIL before any implementation exists
- Cover: happy path, edge cases, error cases
- Use the project's existing test framework
- One test per behavior
- Clear test names that describe expected behavior
- DO NOT write implementation — tests only

After writing, run the tests and confirm they fail."
SCRIPT
chmod +x "$HOME/.local/bin/codex-tdd"

# ── codex-review — code review on changed files ───────────────────────────────
cat > "$HOME/.local/bin/codex-review" << 'SCRIPT'
#!/usr/bin/env bash
# codex-review — code review on git-changed files (equivalent to /code-review in Claude Code)
# Usage: codex-review
set -euo pipefail
CHANGED=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "all files")
exec codex "Review these changed files for code quality: $CHANGED

Check for:
- Unclear names (variables, functions, files)
- Missing or swallowed error handling
- Hardcoded values (should be constants or env vars)
- Mutation (should create new objects instead)
- Functions >20 lines (split into smaller ones)
- Deep nesting (>4 levels — extract functions)
- Missing edge cases
- Over-engineering or unnecessary abstractions

Output findings as: CRITICAL / HIGH / MEDIUM / LOW
Fix CRITICAL and HIGH immediately. Report MEDIUM/LOW for awareness.
Be terse — skip files with no issues."
SCRIPT
chmod +x "$HOME/.local/bin/codex-review"

# ── codex-security — security scan on changed files ──────────────────────────
cat > "$HOME/.local/bin/codex-security" << 'SCRIPT'
#!/usr/bin/env bash
# codex-security — security scan (equivalent to /security-scan in Claude Code)
# Usage: codex-security
set -euo pipefail
CHANGED=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only 2>/dev/null || echo "all files")
exec codex "Security scan these files: $CHANGED

Check for:
- Hardcoded secrets (API keys, passwords, tokens, connection strings)
- SQL injection (non-parameterized queries)
- XSS vulnerabilities (unsanitized HTML output)
- CSRF missing
- Missing authentication/authorization checks
- Sensitive data in logs or error messages
- Missing input validation at system boundaries
- Insecure dependencies (if package files changed)

Output: CRITICAL / HIGH / MEDIUM / LOW severity.
Fix CRITICAL immediately. Report others.
Skip files with no security concerns."
SCRIPT
chmod +x "$HOME/.local/bin/codex-security"

# ── Ensure ~/.local/bin is in PATH ────────────────────────────────────────────
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
if [ -n "$SHELL_RC" ] && ! grep -q '.local/bin' "$SHELL_RC" 2>/dev/null; then
  echo "$PATH_LINE" >> "$SHELL_RC"
  echo "Added ~/.local/bin to PATH in $SHELL_RC"
fi

# ── WUPHF — multi-agent orchestration (97% cache hit rate) ──────────────────
# Codex users can use WUPHF as an orchestration layer across Codex + Claude sessions
cat > "$HOME/.config/wuphf-codex-note.md" << 'EOF'
# WUPHF with Codex

WUPHF primarily targets Claude Code, but Codex users can benefit from the same
multi-agent pattern by running parallel `codex exec` sessions with scoped prompts.

For pure Codex multi-agent work, use the codex-task pipeline which handles
stack detection, L3 recall, and phase orchestration automatically.

To use WUPHF with Claude Code sessions alongside Codex:
  npx wuphf
EOF

cat > "$HOME/.stash/docker-compose.yml" << 'EOF' 2>/dev/null || true
services:
  stash:
    image: ghcr.io/alash3al/stash:latest
    ports:
      - "8765:8765"
    environment:
      - DATABASE_URL=postgresql://stash:stash@postgres:5432/stash?sslmode=disable
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  postgres:
    image: pgvector/pgvector:pg16
    environment:
      - POSTGRES_USER=stash
      - POSTGRES_PASSWORD=stash
      - POSTGRES_DB=stash
    volumes:
      - stash_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL', "pg_isready -U stash"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  stash_data:
EOF

mkdir -p "$HOME/.stash"
cat > "$HOME/.stash/.env.example" << 'EOF'
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
EOF
echo "Stash config: ~/.stash/ (start with docker compose up -d for cross-session memory)"

# ── GitHub auth check ────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Codex setup complete!"
echo ""
echo "Scripts installed to ~/.local/bin:"
echo "  codex-task \"<task>\"   — full pipeline (plan→TDD→implement→review→security)"
echo "  codex-plan \"<task>\"   — planning only"
echo "  codex-tdd \"<task>\"    — add focused tests when requested"
echo "  codex-review          — code review on changed files"
echo "  codex-security        — security scan on changed files"
echo ""
echo "Checking GitHub auth status..."
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  echo "✓ GitHub authenticated — codex-task can push branches and create PRs automatically."
else
  echo "⚠ GitHub not authenticated."
  echo ""
  echo "  codex-task will still do all the code work (branch, implement, test, review)."
  echo "  It just can't push or create PRs automatically."
  echo "  At the end of every codex-task it outputs the exact git commands to run manually."
  echo ""
  echo "  To enable full automation, run once:"
  echo "    gh auth login"
  echo "  (choose GitHub.com → HTTPS → Login with a web browser)"
fi
echo ""
echo "Reload your shell to pick up PATH changes:"
echo "  source ~/.zshrc   (or ~/.bashrc)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
