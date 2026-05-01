# OpenAI Codex CLI Setup Script for Windows
# Run in PowerShell (no Administrator required).
# Usage: .\codex\setup.ps1

Write-Host "Setting up OpenAI Codex CLI configuration..."

# ── Install Codex CLI if missing ──────────────────────────────────────────────
if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Codex CLI..."
    npm install -g @openai/codex
    Write-Host "Codex CLI installed."
} else {
    Write-Host "Codex CLI already installed."
}

# ── $env:USERPROFILE\.codex\config.toml ──────────────────────────────────────
$codexDir = "$env:USERPROFILE\.codex"
New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

@'
# OpenAI Codex CLI Configuration

# Default model — gpt-4.1 is best for coding tasks
model = "gpt-4.1"

# Sandbox: "danger-full-access" lets Codex read/write/run anything (like Claude Code)
# Options: "read-only" | "workspace-write" | "danger-full-access"
sandbox = "danger-full-access"

# Approval: "never" = fully autonomous (like Claude Code auto-approve)
# Options: "untrusted" | "on-request" | "never"
ask_for_approval = "never"

# Parallel tool calls for speed
supports_parallel_tool_calls = true

# Max instruction file size
project_doc_max_bytes = 65536
'@ | Set-Content -Encoding UTF8 "$codexDir\config.toml"

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

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)

---

# Development Workflow

## Feature Implementation Workflow

0. **Research & Reuse** _(mandatory before any new implementation)_
   - Run `gh search repos` and `gh search code` to find existing implementations
   - Check package registries (npm, PyPI, crates.io) before writing utility code
   - Prefer battle-tested libraries over hand-rolled solutions

1. **Plan First**
   - Break down into phases
   - Identify dependencies and risks
   - Write numbered plan before coding

2. **TDD Approach**
   - Write tests first (RED)
   - Implement to pass tests (GREEN)
   - Refactor (IMPROVE)
   - Verify 80%+ coverage

3. **Code Review**
   - Check unclear names, missing error handling, hardcoded values
   - Address CRITICAL and HIGH issues before continuing

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

---

# Context Budget Management

- Never re-read a file already read in this session
- Read only needed lines (targeted searches over full-file reads)
- Batch independent operations together
- Never re-run the same command twice
- Summarize findings — never paste tool output verbatim into prose

---

# Memory Crystallization (L3 Skill SOPs)

Proven task solutions saved as SOPs — recall on similar tasks to skip cold-start reasoning.

## At Task Start — Search L3 Memory

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\memory\L3\" -ErrorAction SilentlyContinue | Where-Object Name -match "<keyword>"
```

If SOP found: read it, use as starting pattern, skip cold reasoning.

## At Task End — Crystallize New SOP

After completing any non-trivial task (3+ implementation steps):
1. Distill what worked into a reusable SOP
2. Save to `~/.codex/memory/L3/<stack>-<domain>-<slug>.md`
3. Keep short — steps + gotchas only, under 30 lines

## SOP Format

```markdown
# SOP: <domain> — <what this covers>
Stack: <language/framework>
Last used: <YYYY-MM-DD>

## Steps
1. ...

## Gotchas
- ...
```

---

# Common Patterns

## Repository Pattern

Encapsulate data access behind a consistent interface:
- Define standard operations: findAll, findById, create, update, delete
- Business logic depends on the abstract interface, not the storage mechanism
- Enables easy swapping of data sources and simplifies testing with mocks

## API Response Format

Use a consistent envelope for all API responses:
- Include a success/status indicator
- Include the data payload (nullable on error)
- Include an error message field (nullable on success)
- Include metadata for paginated responses (total, page, limit)

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

# ── L3 memory directory ───────────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "$codexDir\memory\L3" | Out-Null
Write-Host "L3 memory directory created: $codexDir\memory\L3"

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

# Search L3 memory for relevant SOPs
$Keyword = ($Task -split " ")[0].ToLower()
$SopHint = ""
$L3Dir = "$env:USERPROFILE\.codex\memory\L3"
if (Test-Path $L3Dir) {
    $SopFile = Get-ChildItem $L3Dir -ErrorAction SilentlyContinue | Where-Object Name -match $Keyword | Select-Object -First 1
    if ($SopFile) { $SopHint = "Relevant SOP found: $($SopFile.FullName) — read it and use as starting pattern." }
}

$Prompt = @"
Execute the full development pipeline autonomously for this task: $Task

Stack detected: $Stack
GitHub auth: $GhStatus
$SopHint

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
& codex "Plan this task. Output a numbered breakdown:
- What files change and why
- Before vs after behavior
- How to verify correctness
- Risks and dependencies
- Estimated complexity
Be terse. No implementation yet — just the plan.

Task: $Task"
'@ | Set-Content -Encoding UTF8 "$localBin\codex-plan.ps1"

# codex-tdd
@'
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$TaskArgs)
if (-not $TaskArgs) { Write-Host 'Usage: codex-tdd "<logic to test>"'; exit 1 }
$Task = $TaskArgs -join " "
& codex "Write failing tests (RED phase of TDD) for this logic: $Task

Rules:
- Tests must FAIL before any implementation exists
- Cover: happy path, edge cases, error cases
- Use the project's existing test framework
- Clear test names that describe expected behavior
- DO NOT write implementation — tests only

After writing, run the tests and confirm they fail."
'@ | Set-Content -Encoding UTF8 "$localBin\codex-tdd.ps1"

# codex-review
@'
$Changed = (git diff --name-only HEAD 2>$null) -join ", "
if (-not $Changed) { $Changed = "all files" }
& codex "Review these changed files for code quality: $Changed

Check for:
- Unclear names (variables, functions, files)
- Missing or swallowed error handling
- Hardcoded values (should be constants or env vars)
- Mutation (should create new objects instead)
- Functions >20 lines
- Deep nesting (>4 levels)
- Missing edge cases

Output findings as: CRITICAL / HIGH / MEDIUM / LOW
Fix CRITICAL and HIGH immediately. Be terse — skip files with no issues."
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
Write-Host "Scripts installed to $localBin:"
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
        Write-Host "✓ GitHub authenticated — codex-task can push branches and create PRs automatically."
    } else {
        Write-Host "⚠ GitHub not authenticated."
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
    Write-Host "⚠ gh CLI not found. Install from: https://cli.github.com/"
    Write-Host "  Then run: gh auth login"
}
Write-Host ""
Write-Host "Reload your PowerShell profile to pick up PATH changes:"
Write-Host "  . `$PROFILE"
Write-Host "================================================"
