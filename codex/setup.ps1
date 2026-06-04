# OpenAI Codex CLI Setup Script for Windows
# Run in PowerShell (no Administrator required).
# Usage: .\codex\setup.ps1

Write-Host "Setting up OpenAI Codex CLI configuration..."

function Get-NpmCommand {
    $npmCmd = Get-Command npm.cmd -ErrorAction SilentlyContinue
    if ($npmCmd) { return $npmCmd.Source }

    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if ($npm) { return $npm.Source }

    return $null
}

$npmCommand = Get-NpmCommand

# ── Install Codex CLI if missing ──────────────────────────────────────────────
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    if (-not $npmCommand) {
        Write-Warning "npm not found. Install Node.js/npm, then rerun setup."
    } else {
        Write-Host "Installing Codex CLI..."
        & $npmCommand install -g @openai/codex
        Write-Host "Codex CLI installed."
    }
} else {
    Write-Host "Codex CLI already installed."
}

# ── $env:USERPROFILE\.codex\config.toml ──────────────────────────────────────
$codexDir = "$env:USERPROFILE\.codex"
New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

@'
# OpenAI Codex CLI Configuration

# Strongest default coding model in current Codex catalog.
model = "gpt-5.5"

# Fully autonomous mode for trusted repos.
sandbox = "danger-full-access"

ask_for_approval = "never"

# Speed/context settings.
supports_parallel_tool_calls = true

project_doc_max_bytes = 65536

[desktop]
default-service-tier = "priority"

[windows]
sandbox = "elevated"
'@ | Set-Content -Encoding UTF8 "$codexDir\config.toml"

$reverseMortgagePath = "C:\_Mitesh\repos\reverse-mortgage"
if (Test-Path $reverseMortgagePath) {
@"

[projects.'$reverseMortgagePath']
trust_level = "trusted"
"@ | Add-Content -Encoding UTF8 "$codexDir\config.toml"
}

# Install GitNexus and wire it into Codex MCP when available.
if (-not (Get-Command gitnexus.cmd -ErrorAction SilentlyContinue)) {
    if (-not $npmCommand) {
        Write-Warning "npm not found. Skipping GitNexus install."
    } else {
        Write-Host "Installing GitNexus CLI..."
        & $npmCommand install -g gitnexus@1.6.5
    }
}

$gitnexusCmd = Get-Command gitnexus.cmd -ErrorAction SilentlyContinue
if ((Get-Command codex -ErrorAction SilentlyContinue) -and $gitnexusCmd) {
    $mcpList = (& codex mcp list 2>$null) -join "`n"
    if ($mcpList -notmatch '(^|\s)gitnexus(\s|$)') {
        Write-Host "Adding GitNexus MCP server to Codex..."
        & codex mcp add gitnexus -- $gitnexusCmd.Source mcp
    } else {
        Write-Host "GitNexus MCP already configured."
    }
} else {
    Write-Warning "GitNexus MCP not configured. Install gitnexus and run: codex mcp add gitnexus -- gitnexus.cmd mcp"
}

# ── $env:USERPROFILE\.codex\AGENTS.md — global instructions ──────────────────
@'
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
| ultra | Abbreviate (DB/auth/config/req/res/fn), strip conjunctions, arrows for causality (X -> Y). |

## Auto-Clarity

Drop caveman for: security warnings, irreversible action confirmations, multi-step sequences
where fragment order risks misread. Resume after.

Code/commits/PRs: write normal. Only prose is compressed.

---

# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
WRONG:  modify(original, field, value) -> changes original in-place
CORRECT: update(original, field, value) -> returns new copy with change
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
   - Run `gh search repos` and `gh search code` to find existing implementations
   - Use vendor docs to confirm API behavior before implementing
   - Search npm/PyPI/crates.io before writing utility code
   - Prefer adopting/porting a proven approach over writing net-new code

1. **Plan First**
   - Break down into phases
   - Identify dependencies and risks
   - Write numbered plan before coding
   - Check `CONTEXT.md` for domain terms and ADRs before planning

2. **TDD Approach**
   - Write tests first (RED)
   - Implement to pass tests (GREEN)
   - Refactor (IMPROVE)
   - Verify 80%+ coverage

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

# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows

## TDD Workflow (MANDATORY)
1. Write test first (RED)
2. Run test — it should FAIL
3. Write minimal implementation (GREEN)
4. Run test — it should PASS
5. Refactor (IMPROVE)
6. Verify coverage (80%+)

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
1. `codex-plan "task"` with gpt-4.1 -> get numbered breakdown
2. Switch to o3 for the hardest decision: `/model o3`
3. Switch back for implementation: `/model gpt-4.1`

Never use o3 for simple fixes — cost is 10x gpt-4.1-mini.

---

# Context Budget Management

- Never re-read a file already read in this session
- Read only needed lines (targeted searches over full-file reads)
- Batch independent operations together
- Never re-run the same command twice
- Summarize findings — never paste tool output verbatim into prose

---

# Memory Crystallization — Three-Tier Architecture

Three memory tiers: entity facts (L2), reusable SOPs (L3). L1 = session context (conversation only).

| Tier | What | Location |
|------|------|----------|
| L2 | Entity facts: systems, decisions, people, services | ~/.codex/memory/L2/ |
| L3 | Skill SOPs: proven task patterns per stack/domain | ~/.codex/memory/L3/ |

## L2 Entity Memory (POLE+O)

Save durable facts about project entities:
- Person — roles, preferences ("Alice owns auth module")
- Object — systems, configs ("payments uses Stripe v3")
- Location — repos, environments, paths
- Event — decisions, incidents, migrations
- Organization — teams, external services

Save to ~/.codex/memory/L2/<project>-<entity-type>-<slug>.md
Update (don't duplicate) when facts change.

## L3 SOP Memory — At Task Start

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\memory\L3\" -ErrorAction SilentlyContinue | Where-Object Name -match "<keyword>"
```

If SOP found: read it, use as starting pattern, skip cold reasoning.

## L3 SOP Memory — At Task End

After completing any non-trivial task (3+ implementation steps):
1. Distill what worked into a reusable SOP
2. Save to ~/.codex/memory/L3/<stack>-<domain>-<slug>.md
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

Crystal:
  narrative: "1-2 sentence summary of what was accomplished"
  keyOutcomes:
    - "Decision or change made"
    - "Pattern established"
  filesAffected:
    - "path/to/file"
  lessons:
    - "Reusable insight with confidence: high/medium/low"

Crystals feed into L3 SOPs. Lessons with confidence:high get saved as standalone L3 entries.

## Importance Scale

When noting why a memory matters (1-10):
- 1-3: Routine reads, minor lookups
- 4-6: File edits, command runs, feature additions
- 7-9: Architectural decisions, API contracts, breaking changes
- 10: Critical system changes, security fixes, data migrations

## SOP Format (L3)

# SOP: <domain> — <what this covers>
Stack: <language/framework>
Last used: <YYYY-MM-DD>

## Steps
1. ...

## Gotchas
- ...

## Entity Fact Format (L2)

# Entity: <name>
Type: Person | Object | Location | Event | Organization
Project: <project or "global">
Observed: <YYYY-MM-DD>
Last-verified: <YYYY-MM-DD>
Expires: <YYYY-MM-DD or "never">

## Facts
- ...

## Staleness Rules
- Check `Last-verified` before acting on a L2 fact
- Facts >6 months old without re-verification: flag as POSSIBLY STALE, verify before using
- When confirmed still true: update `Last-verified` date
- When fact changes: update in-place, don't duplicate
- When fact expires: delete the file

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
- NO: `controllers/UserController`, `services/UserService`, `repos/UserRepo`
- YES: `features/CreateUser/handler`, `features/CreateUser/request`, `features/CreateUser/tests`
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

- Lake = boilable: 100% test coverage, full feature, all edge cases. Do it.
- Ocean = not boilable: rewriting an entire system unprompted. Flag it, don't do it.

## Always Boil These Lakes

- Write all tests, not just happy path
- Handle all error cases, not just the obvious one
- Complete the feature, don't leave stubs
- Fix the root cause, not just the symptom

## Anti-Patterns

- "Choose B - it's 90% there with less code" -> if A is correct, do A
- "Defer tests to a follow-up PR" -> tests are the cheapest lake to boil
- "This would take 2 weeks" -> say "2 weeks human / ~1 hour AI-assisted"

## User Sovereignty

Models recommend. Humans decide. Two models agreeing is a strong signal, not a mandate.

- Always present recommendation + reasoning + what context you might be missing
- When you disagree with user's direction: state it once, clearly, then follow their decision
- Never act on a direction change without asking first - even if confident
- The user always has context models lack

---

# Debugging - Iron Law

No fix without confirmed root cause. Four phases, mandatory in order.

## Phase 1 - Investigate
- Reproduce the bug reliably
- Gather all evidence: logs, stack traces, failing tests
- Map what IS happening vs what SHOULD happen
- Do not form hypotheses yet

## Phase 2 - Analyze
- Study the evidence
- Trace the execution path
- Identify where behavior diverges from expectation

## Phase 3 - Hypothesize
- Form ONE specific hypothesis about root cause
- State it: "I believe X causes Y because Z"
- If multiple hypotheses, rank by likelihood and test top one

## Phase 4 - Implement
- Fix ONLY what the hypothesis points to
- Write a regression test that would have caught this
- Verify the fix resolves the original reproduction case

Never implement a fix before completing Phase 3. No root cause = go back to Phase 1.

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
- Run tests, check logs, demonstrate correctness

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
'@ | Set-Content -Encoding UTF8 "$codexDir\AGENTS.md"

# ── AGENTS.md in current directory (project instructions) ────────────────────
@'
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
- Run tests, check logs, demonstrate correctness
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
// GOOD
function canUserDeleteDocument(user: User, document: Document): boolean {
  const isDocumentOwner = user.id === document.ownerId;
  const isAdmin = user.role === 'admin';
  return isDocumentOwner || isAdmin;
}

// AVOID
function canDel(u: User, d: Document) {
  return u.id === d.ownerId ? true : u.role === 'admin' ? true : false;
}
```

---

# Codex Commands

Use the helper scripts installed by setup.ps1:

## Pipeline
- `codex-task "implement X"` — Full pipeline: plan -> TDD -> implement -> review -> security -> SOP
- `codex-plan "feature X"` — Planning only: breakdown + risks
- `codex-tdd "test X"` — TDD phase: write failing tests first
- `codex-review` — Code review on changed files
- `codex-security` — Security scan on changed files

## Daily Workflow

### New Feature
```
1. codex-plan "Build feature"      -> Clear breakdown
2. codex-tdd "Logic test"          -> Tests force clarity
3. codex-task "implement X"        -> Full pipeline
4. codex-review                    -> Catch issues early
5. codex-security (if needed)      -> Verify safety
```

### Bug Fix
```
codex-task "fix bug in X"   -> branch -> plan -> test -> fix -> review
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
'@ | Set-Content -Encoding UTF8 "$PWD\AGENTS.md"

# ── tasks\ in current directory ───────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "$PWD\tasks" | Out-Null

@'
# Todo

## Current Tasks

- [ ] Add tasks here

## Completed

'@ | Set-Content -Encoding UTF8 "$PWD\tasks\todo.md"

@'
# Lessons Learned

Track patterns and corrections here to avoid repeating mistakes.

## Format

**Lesson:** What went wrong or what worked well
**Why:** Root cause or reason
**Rule:** What to do differently next time

---

'@ | Set-Content -Encoding UTF8 "$PWD\tasks\lessons.md"

# ── L2 + L3 memory directories ────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "$codexDir\memory\L2" | Out-Null
New-Item -ItemType Directory -Force -Path "$codexDir\memory\L3" | Out-Null
Write-Host "Memory directories created: $codexDir\memory\L2 and $codexDir\memory\L3"

# ── Helper scripts to $env:USERPROFILE\.local\bin\ ────────────────────────────
$localBin = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Force -Path $localBin | Out-Null

# codex-task — full pipeline orchestrator
@'
# codex-task.ps1 — full dev pipeline orchestrator for Codex CLI
# Equivalent to /task in Claude Code.
# Usage: codex-task "implement dark mode in the settings page"

param([Parameter(ValueFromRemainingArguments=$true)][string[]]$TaskArgs)

if (-not $TaskArgs) {
    Write-Host 'Usage: codex-task "<what to implement, fix, or build>"'
    exit 1
}

$Task = $TaskArgs -join " "

# Detect project stack
$Stack = "unknown"
if (Test-Path "package.json") { $Stack = "Node/TypeScript" }
elseif (Test-Path "go.mod") { $Stack = "Go" }
elseif (Test-Path "Cargo.toml") { $Stack = "Rust" }
elseif ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) { $Stack = "Python" }
elseif ((Test-Path "build.gradle") -or (Test-Path "settings.gradle")) { $Stack = "Kotlin/Android" }
elseif (Test-Path "pubspec.yaml") { $Stack = "Flutter/Dart" }

# Check GitHub auth
$GhStatus = "GH_NOT_AUTHED"
if (Get-Command gh -ErrorAction SilentlyContinue) {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $GhStatus = "GH_AUTHED" }
}

# Search L3 memory and load SOP content if found
$Keyword = ($Task -split " ")[0].ToLower()
$SopBlock = ""
$L3Dir = "$env:USERPROFILE\.codex\memory\L3"
if (Test-Path $L3Dir) {
    $SopFile = Get-ChildItem $L3Dir -ErrorAction SilentlyContinue | Where-Object Name -match $Keyword | Select-Object -First 1
    if ($SopFile) {
        $SopContent = Get-Content $SopFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($SopContent) {
            $SopBlock = "## Recalled SOP from memory: $($SopFile.Name)`n`n$SopContent`n`nUse the steps and gotchas above as your starting pattern. Skip cold reasoning for anything already documented there.`n"
        }
    }
}

$Prompt = @"
Execute the full development pipeline autonomously for this task: $Task

Stack detected: $Stack
GitHub auth: $GhStatus
$SopBlock

Follow ALL phases below without asking for confirmation between them:

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

## Phase 3 — Tests First (RED)
Write failing tests covering expected behavior. Run them — they MUST FAIL.
If they pass before implementation: tests are wrong, fix them first.

## Phase 4 — Implement (GREEN)
Write minimal code to pass tests.
Rules:
- Functions <=20 lines, one responsibility
- No mutation — new objects, never modify in-place
- Explicit error handling — never swallow silently
- No hardcoded values — constants or config
Run tests — ALL must pass before continuing.

## Phase 5 — Code Review
Check all changed files for:
- Unclear names, missing error handling, hardcoded values
- Logic errors, missing edge cases, over-engineering
Fix CRITICAL/HIGH issues. Report MEDIUM but continue.

## Phase 6 — Security (conditional)
Skip for: pure logic, UI styling, config, renaming.
Run for: auth, user input, APIs, DB, file I/O, secrets.
Verify: no hardcoded secrets, inputs validated, SQL parameterized, no data leaks.

## Phase 7 — Crystallize SOP
After non-trivial tasks (3+ steps), save to ~/.codex/memory/L3/<stack>-<domain>-<slug>.md
Format: title, stack, date, steps, gotchas. Under 30 lines.

## Phase 8 — Done + Git Commands
Output summary, then always output:

  git diff main
  git add -A
  git commit -m "<type>: <short description>"
  git push -u origin <branch-name>
  gh pr create --title "<title>" --body "<summary>"

If not authenticated: gh auth login

Always output these commands even if GitHub is authenticated.
Caveman compression active — responses terse but technically precise.
"@

& codex $Prompt
'@ | Set-Content -Encoding UTF8 "$localBin\codex-task.ps1"

# codex-plan
@'
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$TaskArgs)
if (-not $TaskArgs) { Write-Host 'Usage: codex-plan "<feature to plan>"'; exit 1 }
$Task = $TaskArgs -join " "
$Prompt = @"
Plan this task. Output a numbered breakdown:
- What files change and why
- Before vs after behavior
- How to verify correctness
- Risks and dependencies
- Estimated complexity
Be terse. No implementation yet, just the plan.

Task: $Task
"@
& codex $Prompt
'@ | Set-Content -Encoding UTF8 "$localBin\codex-plan.ps1"

# codex-tdd
@'
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$TaskArgs)
if (-not $TaskArgs) { Write-Host 'Usage: codex-tdd "<logic to test>"'; exit 1 }
$Task = $TaskArgs -join " "
$Prompt = @"
Write failing tests (RED phase of TDD) for this logic: $Task

Rules:
- Tests must FAIL before any implementation exists
- Cover: happy path, edge cases, error cases
- Use the project's existing test framework
- Clear test names that describe expected behavior
- DO NOT write implementation, tests only

After writing, run the tests and confirm they fail.
"@
& codex $Prompt
'@ | Set-Content -Encoding UTF8 "$localBin\codex-tdd.ps1"

# codex-review
@'
$Changed = (git diff --name-only HEAD 2>$null) -join ", "
if (-not $Changed) { $Changed = "all files" }
$Prompt = @"
Review these changed files for code quality: $Changed

Check for:
- Unclear names (variables, functions, files)
- Missing or swallowed error handling
- Hardcoded values (should be constants or env vars)
- Mutation (should create new objects instead)
- Functions >20 lines
- Deep nesting (>4 levels)
- Missing edge cases

Output findings as: CRITICAL / HIGH / MEDIUM / LOW.
Fix CRITICAL and HIGH immediately. Be terse, skip files with no issues.
"@
& codex $Prompt
'@ | Set-Content -Encoding UTF8 "$localBin\codex-review.ps1"

# codex-security
@'
$Changed = (git diff --name-only HEAD 2>$null) -join ", "
if (-not $Changed) { $Changed = "all files" }
& codex "Security scan these files: $Changed

Check for:
- Hardcoded secrets (API keys, passwords, tokens, connection strings)
- SQL injection (non-parameterized queries)
- XSS vulnerabilities (unsanitized HTML output)
- CSRF missing
- Missing authentication/authorization checks
- Sensitive data in logs or error messages
- Missing input validation at system boundaries

Output: CRITICAL / HIGH / MEDIUM / LOW severity.
Fix CRITICAL immediately. Skip files with no security concerns."
'@ | Set-Content -Encoding UTF8 "$localBin\codex-security.ps1"

# ── Add ~/.local/bin to PATH in PowerShell profile ────────────────────────────
$ProfilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $ProfilePath)) {
    New-Item -ItemType File -Force -Path $ProfilePath | Out-Null
}
$PathLine = '$env:PATH = "$env:USERPROFILE\.local\bin;" + $env:PATH'
if (-not (Select-String -Path $ProfilePath -Pattern '\.local\\bin' -Quiet -ErrorAction SilentlyContinue)) {
    Add-Content -Path $ProfilePath -Value $PathLine
    Write-Host "Added ~/.local/bin to PATH in PowerShell profile."
}

# ── Create cmd wrappers so commands work without .ps1 extension ───────────────
foreach ($cmd in @("codex-task", "codex-plan", "codex-tdd", "codex-review", "codex-security")) {
    @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.local\bin\$cmd.ps1" %*
"@ | Set-Content -Encoding ASCII "$localBin\$cmd.cmd"
}

Write-Host ""
Write-Host "================================================"
Write-Host "Codex setup complete!"
# ── WUPHF + Stash config for Codex users ─────────────────────────────────────
$stashDir = "$env:USERPROFILE\.stash"
New-Item -ItemType Directory -Force -Path $stashDir | Out-Null

@'
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
      test: ["CMD-SHELL", "pg_isready -U stash"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  stash_data:
'@ | Set-Content -Encoding UTF8 "$stashDir\docker-compose.yml"

@'
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
'@ | Set-Content -Encoding UTF8 "$stashDir\.env.example"

Write-Host "Stash config: $stashDir (run docker compose up -d for cross-session memory)"

Write-Host ""
Write-Host "Scripts installed to ${localBin}:"
Write-Host "  codex-task `"<task>`"   -- full pipeline (plan->TDD->implement->review->security)"
Write-Host "  codex-plan `"<task>`"   -- planning only"
Write-Host "  codex-tdd `"<task>`"    -- write failing tests first"
Write-Host "  codex-review          -- code review on changed files"
Write-Host "  codex-security        -- security scan on changed files"
Write-Host ""
Write-Host "Checking GitHub auth status..."
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if ($ghInstalled) {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "GitHub authenticated - codex-task can push branches and create PRs automatically."
    } else {
        Write-Host "GitHub not authenticated."
        Write-Host ""
        Write-Host "  codex-task will still do all code work (branch, implement, test, review)."
        Write-Host "  It just can't push or create PRs automatically."
        Write-Host "  At end of every codex-task it outputs the exact git commands to run manually."
        Write-Host ""
        Write-Host "  To enable full automation, run once:"
        Write-Host "    gh auth login"
        Write-Host "  (choose GitHub.com -> HTTPS -> Login with a web browser)"
    }
} else {
    Write-Host "gh CLI not found. Install from: https://cli.github.com/"
    Write-Host "  Then run: gh auth login"
}
Write-Host ""
Write-Host "Reload your PowerShell profile to pick up PATH changes:"
Write-Host '  . $PROFILE'
Write-Host "================================================"
