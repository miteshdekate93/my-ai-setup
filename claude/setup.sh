#!/usr/bin/env bash
set -euo pipefail

# Claude Code Setup Script
# Run this on any new Mac to restore your full Claude Code configuration.
# Usage: bash my-claude-setup.sh

echo "Setting up Claude Code configuration..."

# ── ~/.claude/settings.json ──────────────────────────────────────────────────
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" << 'EOF'
{
  "voiceEnabled": true,
  "disabledMcpServers": ["railway", "vercel"]
}
EOF

# ── ~/.claude/rules/ ──────────────────────────────────────────────────────────
mkdir -p "$HOME/.claude/rules"

cat > "$HOME/.claude/rules/agents.md" << 'EOF'
# Agent Orchestration

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| build-error-resolver | Fix build errors | When build fails |
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation | Updating docs |
| rust-reviewer | Rust code review | Rust projects |

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
EOF

cat > "$HOME/.claude/rules/coding-style.md" << 'EOF'
# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
// Pseudocode
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Rationale: Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

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
EOF

cat > "$HOME/.claude/rules/development-workflow.md" << 'EOF'
# Development Workflow

> This file extends [common/git-workflow.md](./git-workflow.md) with the full feature development process that happens before git operations.

The Feature Implementation Workflow describes the development pipeline: research, planning, TDD, code review, and then committing to git.

## Feature Implementation Workflow

0. **Research & Reuse** _(mandatory before any new implementation)_
   - **GitHub code search first:** Run `gh search repos` and `gh search code` to find existing implementations, templates, and patterns before writing anything new.
   - **Library docs second:** Use Context7 or primary vendor docs to confirm API behavior, package usage, and version-specific details before implementing.
   - **Exa only when the first two are insufficient:** Use Exa for broader web research or discovery after GitHub search and primary docs.
   - **Check package registries:** Search npm, PyPI, crates.io, and other registries before writing utility code. Prefer battle-tested libraries over hand-rolled solutions.
   - **Search for adaptable implementations:** Look for open-source projects that solve 80%+ of the problem and can be forked, ported, or wrapped.
   - Prefer adopting or porting a proven approach over writing net-new code when it meets the requirement.

1. **Plan First**
   - Use **planner** agent to create implementation plan
   - Generate planning docs before coding: PRD, architecture, system_design, tech_doc, task_list
   - Identify dependencies and risks
   - Break down into phases

2. **TDD Approach**
   - Use **tdd-guide** agent
   - Write tests first (RED)
   - Implement to pass tests (GREEN)
   - Refactor (IMPROVE)
   - Verify 80%+ coverage

3. **Code Review**
   - Use **code-reviewer** agent immediately after writing code
   - Address CRITICAL and HIGH issues
   - Fix MEDIUM issues when possible

4. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format
   - See [git-workflow.md](./git-workflow.md) for commit message format and PR process
EOF

cat > "$HOME/.claude/rules/git-workflow.md" << 'EOF'
# Git Workflow

## Commit Message Format
```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

Note: Attribution disabled globally via ~/.claude/settings.json.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

> For the full development process (planning, TDD, code review) before git operations,
> see [development-workflow.md](./development-workflow.md).
EOF

cat > "$HOME/.claude/rules/hooks.md" << 'EOF'
# Hooks System

## Hook Types

- **PreToolUse**: Before tool execution (validation, parameter modification)
- **PostToolUse**: After tool execution (auto-format, checks)
- **Stop**: When session ends (final verification)

## Auto-Accept Permissions

Use with caution:
- Enable for trusted, well-defined plans
- Disable for exploratory work
- Never use dangerously-skip-permissions flag
- Configure `allowedTools` in `~/.claude.json` instead

## TodoWrite Best Practices

Use TodoWrite tool to:
- Track progress on multi-step tasks
- Verify understanding of instructions
- Enable real-time steering
- Show granular implementation steps

Todo list reveals:
- Out of order steps
- Missing items
- Extra unnecessary items
- Wrong granularity
- Misinterpreted requirements
EOF

cat > "$HOME/.claude/rules/patterns.md" << 'EOF'
# Common Patterns

## Skeleton Projects

When implementing new functionality:
1. Search for battle-tested skeleton projects
2. Use parallel agents to evaluate options:
   - Security assessment
   - Extensibility analysis
   - Relevance scoring
   - Implementation planning
3. Clone best match as foundation
4. Iterate within proven structure

## Design Patterns

### Repository Pattern

Encapsulate data access behind a consistent interface:
- Define standard operations: findAll, findById, create, update, delete
- Concrete implementations handle storage details (database, API, file, etc.)
- Business logic depends on the abstract interface, not the storage mechanism
- Enables easy swapping of data sources and simplifies testing with mocks

### API Response Format

Use a consistent envelope for all API responses:
- Include a success/status indicator
- Include the data payload (nullable on error)
- Include an error message field (nullable on success)
- Include metadata for paginated responses (total, page, limit)
EOF

cat > "$HOME/.claude/rules/performance.md" << 'EOF'
# Performance Optimization

## Model Selection Strategy

**Haiku 4.5** (90% of Sonnet capability, 3x cost savings):
- Lightweight agents with frequent invocation
- Pair programming and code generation
- Worker agents in multi-agent systems

**Sonnet 4.6** (Best coding model):
- Main development work
- Orchestrating multi-agent workflows
- Complex coding tasks

**Opus 4.5** (Deepest reasoning):
- Complex architectural decisions
- Maximum reasoning requirements
- Research and analysis tasks

## Context Window Management

Avoid last 20% of context window for:
- Large-scale refactoring
- Feature implementation spanning multiple files
- Debugging complex interactions

Lower context sensitivity tasks:
- Single-file edits
- Independent utility creation
- Documentation updates
- Simple bug fixes

## Extended Thinking + Plan Mode

Extended thinking is enabled by default, reserving up to 31,999 tokens for internal reasoning.

Control extended thinking via:
- **Toggle**: Option+T (macOS) / Alt+T (Windows/Linux)
- **Config**: Set `alwaysThinkingEnabled` in `~/.claude/settings.json`
- **Budget cap**: `export MAX_THINKING_TOKENS=10000`
- **Verbose mode**: Ctrl+O to see thinking output

For complex tasks requiring deep reasoning:
1. Ensure extended thinking is enabled (on by default)
2. Enable **Plan Mode** for structured approach
3. Use multiple critique rounds for thorough analysis
4. Use split role sub-agents for diverse perspectives

## Build Troubleshooting

If build fails:
1. Use **build-error-resolver** agent
2. Analyze error messages
3. Fix incrementally
4. Verify after each fix
EOF

cat > "$HOME/.claude/rules/security.md" << 'EOF'
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

## Security Response Protocol

If security issue found:
1. STOP immediately
2. Use **security-reviewer** agent
3. Fix CRITICAL issues before continuing
4. Rotate any exposed secrets
5. Review entire codebase for similar issues
EOF

cat > "$HOME/.claude/rules/testing.md" << 'EOF'
# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test-Driven Development

MANDATORY workflow:
1. Write test first (RED)
2. Run test - it should FAIL
3. Write minimal implementation (GREEN)
4. Run test - it should PASS
5. Refactor (IMPROVE)
6. Verify coverage (80%+)

## Troubleshooting Test Failures

1. Use **tdd-guide** agent
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)

## Agent Support

- **tdd-guide** - Use PROACTIVELY for new features, enforces write-tests-first
EOF

cat > "$HOME/.claude/rules/memory-crystallization.md" << 'EOF'
# Memory Crystallization (L3 Skill SOPs)

Inspired by GenericAgent's self-crystallization pattern: proven task solutions saved as SOPs,
recalled on similar tasks to skip cold-start reasoning. Compound savings after ~10 tasks.

## At Task Start — Search L3 Memory

Before starting any non-trivial task, search for relevant SOPs:

```bash
ls ~/.claude/memory/L3/ 2>/dev/null | grep -i "<keyword>"
```

Keywords: match domain of task (auth, api, database, testing, migration, deploy, etc.)

- SOP found → read it, use as starting pattern, skip cold reasoning
- No match → proceed normally, crystallize at end

## At Task End — Crystallize New SOP

After completing any non-trivial task (3+ implementation steps):
1. Distill what worked into a reusable SOP
2. Save to `~/.claude/memory/L3/<stack>-<domain>-<slug>.md`
3. Keep it short — steps + gotchas only, no boilerplate

Skip crystallization for: one-liners, config tweaks, pure Q&A, trivial renames.

## SOP Format

```markdown
# SOP: <domain> — <what this covers>
Stack: <language/framework>
Last used: <YYYY-MM-DD>

## Steps
1. ...
2. ...

## Gotchas
- ...
```

## Examples

- `~/.claude/memory/L3/node-jwt-auth.md` — JWT middleware setup in Express
- `~/.claude/memory/L3/go-grpc-service.md` — gRPC service scaffold in Go
- `~/.claude/memory/L3/python-alembic-migration.md` — Alembic DB migration pattern
- `~/.claude/memory/L3/react-context-state.md` — Context + useReducer state pattern

## Directory

All SOPs live in: `~/.claude/memory/L3/`
EOF

cat > "$HOME/.claude/rules/context-budget.md" << 'EOF'
# Context Budget Management

Inspired by GenericAgent's 6x token efficiency. Stay lean, batch aggressively, compress early.

## File Reading

- Never re-read a file already read in this session — check conversation context first
- Read only needed lines (use offset + limit, not full file reads)
- Batch all independent file reads in one message (parallel tool calls)
- Prefer grep/glob over reading entire files for targeted searches

## Tool Call Batching

ALWAYS batch independent tool calls in one message. Never sequential when parallel works.

```
GOOD: Read file A + Read file B + Run test → one message, 3 tool calls
BAD:  Read file A → wait → Read file B → wait → Run test
```

Never re-run the same command twice. Cache results mentally.

## Context Trimming Triggers

When session is long (10+ tool-use turns or feels heavy):
- Stop re-reading files already seen
- Compress status updates to one sentence
- Prefer diffs over full file reads for code review
- Spawn subagents for new sub-tasks to keep main context clean

## Summarize, Don't Quote

Never paste tool output verbatim into prose. Summarize findings:

```
BAD:  "The output of git status was: On branch main\n Changes not staged..."
GOOD: "2 files modified, not staged."
```

## What NOT to Do

- Don't read CLAUDE.md or rule files at session start (already loaded)
- Don't re-run `git status` after every file edit (batch at end)
- Don't repeat the user's request back before answering
- Don't summarize what you just did (user can see tool calls)
- Don't add trailing "Summary of changes" paragraphs after edits

## Turn Budget Check

Every 10 tool-use turns: assess context bloat.
- Bloating → spawn subagent for next chunk
- Clean → continue in main session
EOF

# ── CLAUDE.md in current directory ───────────────────────────────────────────
cat > "$PWD/CLAUDE.md" << 'EOF'
# Workflow Orchestration

## 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

## 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

## 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

## 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

## 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

## 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

---

# Code Style: Readable & Explainable

**Principle:** Simple code > Clever code. You must be able to explain it in 2 minutes.

## Functions: Short & Clear
- **Max 20 lines per function** — else break it into smaller ones
- **One responsibility** — if it does A and B, split it
- **Clear names** — not `u`, `d`, `x` — use `user`, `document`, `count`

```typescript
// ✅ GOOD: Clear intent, easy to test, explainable
function canUserDeleteDocument(user: User, document: Document): boolean {
  const isDocumentOwner = user.id === document.ownerId;
  const isAdmin = user.role === 'admin';
  return isDocumentOwner || isAdmin;
}

// ❌ AVOID: Nested logic, hard to explain
function canDel(u: User, d: Document) {
  return u.id === d.ownerId ? true : u.role === 'admin' ? true : false;
}
```

## Variable Names: Explicit, Readable
```typescript
// ✅ GOOD: Anyone reading this aloud understands it
const userHasAccessToSharedDocument = user.sharedDocuments.includes(docId);
const documentOwnerEmail = document.owner.email;
const maxLoginAttemptsBeforeLockout = 5;

// ❌ AVOID: Abbreviations, single letters
const hasAccess = u.docs.includes(d);
const ownerMail = doc.o.e;
const max = 5;
```

## Comments: Explain WHY, Not WHAT
```typescript
// ✅ GOOD: Why is this needed? Business rule? Technical constraint?
const MAX_LOGIN_ATTEMPTS = 5;  // Security: Prevent brute-force attacks

// ✅ GOOD: Complex logic gets a one-liner before the code
// Only process documents modified in last 24h to avoid re-indexing entire dataset
const recentDocuments = documents.filter(d => {
  const oneDayAgo = Date.now() - (24 * 60 * 60 * 1000);
  return d.modifiedAt > oneDayAgo;
});

// ❌ AVOID: Comments that just repeat code
const user = getUserById(id);  // Get user by ID
```

## Error Messages: Helpful
```typescript
// ✅ GOOD: User knows what went wrong + how to fix it
if (!req.body.userEmail) {
  return res.status(400).json({
    error: 'Missing userEmail in request body',
    example: { userEmail: 'john@example.com' }
  });
}

// ❌ AVOID: Cryptic errors
if (!req.body.email) {
  return res.status(400).json({ error: 'Invalid input' });
}
```

---

# ECC Commands

Skills from the \`everything-claude-code\` marketplace. Invoke as \`/skill-name\` (short form) — no \`everything-claude-code:\` prefix needed.

## Planning & Design
- \`/plan\` — Structure and break down a feature before coding
- \`/blueprint\` — Architecture blueprint for new projects

## Testing
- \`/tdd\` — Test-driven development (write tests first, RED → GREEN → IMPROVE)
- \`/e2e\` — End-to-end tests for critical user flows

## Code Review (language-specific)
- \`/python-review\` — Python code review
- \`/go-review\` — Go code review
- \`/rust-review\` — Rust code review
- \`/kotlin-review\` — Kotlin/Android code review
- \`/flutter-dart-code-review\` — Flutter/Dart code review

## Security
- \`/security-scan\` — Scan for hardcoded secrets, injection, auth bypasses
- \`/security-review\` — Deeper security analysis

## Build & Fix
- \`/go-build\` — Fix Go build/vet errors
- \`/rust-build\` — Fix Rust/Cargo errors
- \`/kotlin-build\` — Fix Kotlin/Gradle errors
- \`/gradle-build\` — Fix Gradle build errors

## Other
- \`/docs\` — Update documentation and codemaps
- \`/prune\` — Remove dead code and unused dependencies
- \`/prompt-optimize\` — Optimize prompts for LLM pipelines

## Core Workflow Skills
**When:** Starting a feature or fixing a bug — use this order:
```
1. /plan "Build feature"          → Clear breakdown
2. /tdd "Logic test"              → Tests force clarity
3. /python-review (or language)   → Catch issues early
4. /security-scan (if needed)     → Verify safety
```

---

# Daily Workflow

## New Feature (2–3 hours)
```
1. /plan "Build feature"               (10 min)  → Clear breakdown
2. Read plan aloud to yourself          (5 min)  → If confused, re-plan
3. /tdd "Logic test"                   (45 min)  → Tests force clarity
4. Implement minimal code              (30 min)  → Just make tests pass
5. /python-review (or language-review) (10 min)  → Catch issues early
6. /security-scan (if needed)           (5 min)  → Verify safety
7. Submit                               (5 min)
```

## Bug Fix (30 min)
```
1. /plan "Reproduce bug, plan fix"     (5 min)
2. Write failing test                  (5 min)
3. Fix code                           (15 min)
4. /python-review (or language-review) (5 min)
5. Submit
```

## When You Get Stuck
```
/go-build / /rust-build / /kotlin-build  → If compilation error (use your language)
/python-review (or language-review)      → If logic error or unclear code
Check tasks/lessons.md                   → Is this a pattern you've seen before?
```

---

# Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

---

# Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
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

# ── GitNexus skill (/gitnexus-init) ──────────────────────────────────────────
mkdir -p "$HOME/.claude/commands"
cat > "$HOME/.claude/commands/gitnexus-init.md" << 'EOF'
---
description: Initialize GitNexus MCP in the current project for codebase intelligence (impact analysis, dependency chains, 360° symbol context).
---

# /gitnexus-init

## Purpose

Set up GitNexus in the current project so Claude has deep code intelligence — dependency graphs, impact analysis ("what breaks if I change X"), and 360° context for any symbol. Works via MCP with 16 tools available automatically in every Claude Code session after setup.

## What It Does

1. Adds GitNexus as a global MCP server (`claude mcp add`)
2. Indexes the current project codebase (`gitnexus analyze`)
3. Confirms the MCP tools are available

## Workflow

Run the following steps in order:

### Step 1 — Add GitNexus MCP server (one-time global setup)

Check if already configured:
```bash
claude mcp list
```

If `gitnexus` is not listed, add it:

**macOS/Linux:**
```bash
claude mcp add gitnexus -- npx -y gitnexus@latest mcp
```

**Windows:**
```bash
claude mcp add gitnexus -- cmd /c npx -y gitnexus@latest mcp
```

### Step 2 — Index the current project

```bash
npx gitnexus analyze
```

This indexes the codebase, installs agent skills, registers Claude Code hooks, and creates context files. Re-run after large refactors or when the index feels stale.

### Step 3 — Confirm

Tell the user:
- GitNexus MCP is active with 16 code intelligence tools
- Claude will now automatically use dependency/impact context when analyzing, refactoring, or debugging code in this project
- Re-run `/gitnexus-init` (step 2 only) after major refactors to refresh the index

## When to Use

- Starting work on an unfamiliar or large codebase
- Before a significant refactor — get impact analysis first
- When Claude seems to miss cross-file dependencies
- On any project where "what uses this function?" matters
EOF

# ── Caveman rule — always-on token compression (~65% fewer output tokens) ─────
cat > "$HOME/.claude/rules/caveman.md" << 'EOF'
# Caveman Mode — Always Active

Respond terse like smart caveman. All technical substance stay. Only fluff die.

## Rules

Drop: articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries
(sure/certainly/of course/happy to), hedging. Fragments OK. Short synonyms (big not extensive,
fix not "implement a solution for"). Technical terms exact. Code blocks unchanged. Errors quoted exact.

Pattern: `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help you with that. The issue you're experiencing is likely caused by..."
Yes: "Bug in auth middleware. Token expiry check use `<` not `<=`. Fix:"

## Intensity

Default: **full** (drop articles, fragments OK, short synonyms).

Switch: `/caveman lite` | `/caveman full` | `/caveman ultra`
Stop: "stop caveman" or "normal mode"

| Level | Behavior |
|-------|----------|
| lite | No filler/hedging. Keep articles + full sentences. Tight but readable. |
| full | Drop articles, fragments OK, short synonyms. Classic caveman. |
| ultra | Abbreviate (DB/auth/config/req/res/fn), strip conjunctions, arrows for causality (X → Y). |

## Auto-Clarity

Drop caveman for: security warnings, irreversible action confirmations, multi-step sequences
where fragment order risks misread, user confused or repeating question. Resume caveman after.

Example — destructive op:
> **Warning:** This will permanently delete all rows in the `users` table and cannot be undone.
> Caveman resume after warning.

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
| "As an AI" / "As a language model" | never say |

Examples:
- "You might want to use X" → "Use X"
- "I think the issue is Y" → "Issue: Y"
- "It seems like Z is broken" → "Z broken"
- "Perhaps consider adding tests" → "Add tests"

## Boundaries

Code/commits/PRs: write normal. Only prose is compressed.
EOF

# ── Archon rule — auto workflow dispatch for implement/fix/build requests ──────
cat > "$HOME/.claude/rules/archon.md" << 'EOF'
# Archon — Automatic Workflow Engine

For any non-trivial coding task, automatically delegate to Archon CLI. Do NOT ask user first.
Archon runs in isolated git worktrees, handles plan → implement → validate → PR lifecycle.

## Auto-Trigger: Use Archon When

| User Says | Archon Workflow | Branch Pattern |
|-----------|----------------|----------------|
| "implement X", "build X", "create feature" | `archon-idea-to-pr` | `feat/{short-name}` |
| "fix issue #N", "resolve issue" | `archon-fix-github-issue` | `fix/issue-{N}` |
| "fix bug in X", "debug X" (needs investigation) | `archon-fix-github-issue` | `fix/{short-name}` |
| "implement from plan", "execute this plan" | `archon-feature-development` | `feat/{short-name}` |
| "refactor X" | `archon-refactor-safely` | `refactor/{short-name}` |
| "review PR #N" | `archon-comprehensive-pr-review` | `review/pr-{N}` |
| "create a PRD", "plan this feature" | `archon-interactive-prd` | `prd/{short-name}` |

## Skip Archon When

- Answering a question / explaining code
- Single-line or trivial fix (typo, rename, one-liner)
- Reading or searching files
- Running tests directly
- Simple config change

## How to Run (Always Background)

ALWAYS use `run_in_background: true`. Workflows are long-running (plan + implement + PR).

```bash
archon workflow run <workflow-name> --branch <branch-name> "<user request verbatim>"
```

Immediately tell user:
> "Archon running `<workflow>` on branch `<branch>`. Working autonomously — I'll notify you when done."

## Example Dispatches

User: "implement dark mode in the settings page"
→ `archon workflow run archon-idea-to-pr --branch feat/dark-mode "implement dark mode in the settings page"`

User: "fix issue #42"
→ `archon workflow run archon-fix-github-issue --branch fix/issue-42 "fix issue #42"`

User: "refactor the auth module to use the repository pattern"
→ `archon workflow run archon-refactor-safely --branch refactor/auth-module "refactor the auth module to use the repository pattern"`

## If Archon Not Installed

Check: `which archon`

If missing, tell user:
> "Archon CLI not installed. Run: `curl -fsSL https://archon.diy/install | bash`
> Then re-run your request."

Do not attempt the task without Archon for non-trivial work.

## Isolation Mode

Always use `--branch` flag. Never use `--no-worktree` unless user explicitly says "no worktree".
Each task gets its own isolated branch — no conflicts with main.
EOF

# ── /task command — full pipeline orchestrator ────────────────────────────────
cat > "$HOME/.claude/commands/task.md" << 'EOF'
---
description: >
  Autonomous full dev pipeline in one command. Routes complex tasks to Archon (plan+implement+validate+PR)
  or runs inline pipeline (plan → TDD → implement → code-review → security). Zero babysitting.
  Gracefully degrades if GitHub not authenticated — does the code work, outputs git commands to run manually.
argument-hint: "<what to implement, fix, or build>"
---

# /task $ARGUMENTS

Execute the full development pipeline autonomously. Do not ask for confirmation between phases.
Caveman compression is active — responses terse but technically precise.

---

## Step 0 — Context Load (silent, always)

### Detect project stack
Check current dir + parents for these files:

| File | Stack | Review agent for Phase 5 |
|------|-------|--------------------------|
| `package.json` / `bun.lockb` / `deno.json` | Node/TypeScript | `/typescript-review` |
| `go.mod` | Go | `/go-review` |
| `Cargo.toml` | Rust | `/rust-review` |
| `requirements.txt` / `pyproject.toml` / `setup.py` | Python | `/python-review` |
| `build.gradle` / `settings.gradle` | Kotlin/Android | `/kotlin-review` |
| `pubspec.yaml` | Flutter/Dart | `/flutter-dart-code-review` |
| None detected | Generic | manual review |

Store detected stack — auto-invoke matching agent in Phase 5.

### Search L3 memory for relevant SOPs
```bash
ls ~/.claude/memory/L3/ 2>/dev/null | grep -i "<keyword-from-task>"
```
If SOP found: read it and use as starting pattern, skip cold reasoning.

### Auth check
```bash
gh auth status 2>/dev/null && echo "GH_AUTHED" || echo "GH_NOT_AUTHED"
```
- `GH_NOT_AUTHED` → force Inline Pipeline for all task types

---

## Step 1 — Classify

| Task type | Authenticated | Not authenticated |
|-----------|--------------|-------------------|
| New feature / implement / build / add | Archon: `archon-piv-loop` | Inline pipeline |
| Bug fix / fix issue #N / resolve | Archon: `archon-fix-github-issue` | Inline pipeline |
| Review PR #N | Archon: `archon-smart-pr-review` | Inline pipeline (read-only review, no push) |
| Refactor / rename / reorganize | Inline pipeline | Inline pipeline |
| Simple ≤2-file fix | Inline pipeline | Inline pipeline |
| Question / explanation | Answer directly | Answer directly |

---

## Route A — Archon (authenticated only, background, creates PR)

Run with `run_in_background: true`. Never block the conversation.

```bash
# Feature:
archon workflow run archon-piv-loop --branch feat/<short-slug> "$ARGUMENTS"

# Bug fix:
archon workflow run archon-fix-github-issue --branch fix/<short-slug> "$ARGUMENTS"

# PR review:
archon workflow run archon-smart-pr-review --branch review/pr-<N> "$ARGUMENTS"
```

Report to user:
> "Archon: `<workflow>` → branch `<branch>`. Running autonomously. Monitor: `archon workflow status`"

Stop here — Archon handles the rest.

---

## Route B — Inline Pipeline (always available, no GitHub needed)

Work through all phases. One-line status per phase. No skipping.

### Phase 1 — Branch
Create a local branch first:
```bash
git checkout -b <type>/<short-slug>
```

### Phase 2 — Plan
Break down the task:
- What files change and why
- Before vs after behavior
- How to verify
- Risks / dependencies

Write numbered list. Show it. Confirm before proceeding.

### Phase 3 — Tests First (RED)
Write failing tests covering expected behavior. Run them — must FAIL.
If tests pass before implementation: tests are wrong, fix them.

### Phase 4 — Implement (GREEN)
Minimal code to pass tests.
- Functions ≤20 lines, one responsibility
- No mutation — new objects, never modify in-place
- Explicit error handling — never swallow silently
- No hardcoded values — constants or config

Run tests. All must pass before continuing.

### Phase 5 — Code Review (stack-aware)
Use the review agent detected in Step 0:
- Node/TS → `/typescript-review` | Go → `/go-review` | Rust → `/rust-review`
- Python → `/python-review` | Kotlin → `/kotlin-review` | Flutter → `/flutter-dart-code-review`
- Unknown → manual review

Check all changed files:
- Unclear names, missing error handling, hardcoded values
- Logic errors, missing edge cases, over-engineering

Fix CRITICAL/HIGH. Report MEDIUM but continue.

### Phase 6 — Security (conditional)
Skip: pure logic, UI styling, config, renaming.
Run: auth, user input, APIs, DB, file I/O, secrets.
- No hardcoded secrets
- Inputs validated
- SQL parameterized
- No data leaks in logs/errors

### Phase 7 — Crystallize SOP
After non-trivial tasks (3+ implementation steps), save a reusable SOP:
```bash
mkdir -p ~/.claude/memory/L3/
```
Write `~/.claude/memory/L3/<stack>-<domain>-<slug>.md` with:
- Title, stack, date, numbered steps, gotchas. Keep under 30 lines.

Skip for: one-liners, config tweaks, pure Q&A.

### Phase 8 — Done + Git Commands

Report summary. Then always output these commands so user can push/PR manually if needed:

```bash
# Review what changed:
git diff main

# Commit:
git add -A
git commit -m "<type>: <short description of what was done>"

# Push (needs: gh auth login OR git credentials):
git push -u origin <branch-name>

# Create PR (needs: gh auth login):
gh pr create --title "<title>" --body "<summary of changes>"

# If not authenticated yet:
gh auth login
# then re-run the push and pr create commands above
```

Always output these commands even if GitHub is authenticated — user may want to review before pushing.
EOF

# ── L3 memory directory ───────────────────────────────────────────────────────
mkdir -p "$HOME/.claude/memory/L3"
echo "L3 memory directory created: ~/.claude/memory/L3/"

# ── Archon CLI install ────────────────────────────────────────────────────────
if ! command -v archon &>/dev/null && [ ! -f "$HOME/.local/bin/archon" ]; then
  echo "Installing Archon CLI..."
  mkdir -p "$HOME/.local/bin"
  ARCH=$(uname -m)
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ARCHON_BINARY="archon-${OS}-arm64"
  else
    ARCHON_BINARY="archon-${OS}-x64"
  fi
  curl -fsSL "https://github.com/coleam00/Archon/releases/latest/download/${ARCHON_BINARY}" \
    -o "$HOME/.local/bin/archon" && chmod +x "$HOME/.local/bin/archon"
  echo "Archon CLI installed to ~/.local/bin/archon"
  echo "Ensure ~/.local/bin is in your PATH (add to ~/.zshrc or ~/.bashrc):"
  echo '  export PATH="$HOME/.local/bin:$PATH"'
else
  echo "Archon CLI already installed"
fi

# ── Archon config — point to Claude binary ────────────────────────────────────
mkdir -p "$HOME/.archon"
CLAUDE_BIN=$(command -v claude 2>/dev/null || echo "/opt/homebrew/bin/claude")
cat > "$HOME/.archon/config.yaml" << EOF
assistants:
  claude:
    claudeBinaryPath: ${CLAUDE_BIN}
EOF
echo "Archon config written: ~/.archon/config.yaml (claudeBinaryPath=${CLAUDE_BIN})"

# ── Symlink ECC commands to ~/.claude/commands/ (short-form slash commands) ───
# This makes /tdd, /plan, /code-review etc work without the everything-claude-code: prefix
mkdir -p "$HOME/.claude/commands"
ECC_COMMANDS="$HOME/.claude/plugins/marketplaces/everything-claude-code/commands"
if [ -d "$ECC_COMMANDS" ]; then
  for f in "$ECC_COMMANDS"/*.md; do
    ln -sf "$f" "$HOME/.claude/commands/$(basename "$f")"
  done
  echo "Linked ECC commands to ~/.claude/commands/"
else
  echo "Warning: ECC commands not found at $ECC_COMMANDS (install ECC plugin first)"
fi

# ── GitHub auth check ────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup complete!"
echo ""
echo "Checking GitHub auth status..."
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "✓ GitHub authenticated — Archon can push branches and create PRs automatically."
else
  echo "⚠ GitHub not authenticated."
  echo ""
  echo "  /task will still do all the code work (branch, implement, test, review)."
  echo "  It just can't push or create PRs automatically."
  echo "  At the end of every /task it outputs the exact git commands to run manually."
  echo ""
  echo "  To enable full automation, run once:"
  echo "    gh auth login"
  echo "  (choose GitHub.com → HTTPS → Login with a web browser)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
