# Claude Code Setup Script for Windows
# Run in PowerShell as Administrator.
# Usage: .\setup.ps1

Write-Host "Setting up Claude Code configuration..."

# ── $env:USERPROFILE\.claude\settings.json ───────────────────────────────────
$claudeDir = "$env:USERPROFILE\.claude"
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

@'
{
  "voiceEnabled": true,
  "disabledMcpServers": ["railway", "vercel"]
}
'@ | Set-Content -Encoding UTF8 "$claudeDir\settings.json"

# ── $env:USERPROFILE\.claude\rules\ ──────────────────────────────────────────
$rulesDir = "$claudeDir\rules"
New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null

@'
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

If prompt is vague, proceed with safest scoped interpretation and state assumptions. Ask only when missing detail can cause data loss, security issue, or wrong product behavior.

## Minimal Safe Ladder

Before coding: prove need, reuse existing code, use framework/platform, use installed dependency, then add smallest new code.
Never simplify away validation, authorization, PII/secret safety, SQL injection protection, error handling, accessibility, auditability, or requested behavior.

## Tool And Token Discipline

- Start with GitNexus, rg, git grep, and targeted file reads.
- Prefer llms.txt, official docs, vendor docs, and compact project docs when available.
- Batch independent reads/searches.
- Use tool evidence before root-cause or impact claims.
- For architecture-heavy work, check existing ADRs/diagrams and ask whether LikeC4/C4/docs should be updated.
- For CRUD/internal admin apps, prefer schema-first patterns and existing generated/configured UI paths before hand-building screens.
'@ | Set-Content -Encoding UTF8 "$rulesDir\smart-agent-defaults.md"

@'
# Technology Focus

Default stack: React, Angular, TypeScript, C#/.NET, ASP.NET Core, Azure DevOps/IIS/App Services/Key Vault/App Configuration, SQL Server, Oracle, and Claude/Codex automation.

Do not propose Python implementations, PyPI packages, or Python scripts unless the repo is already Python or user explicitly asks. For automation prefer PowerShell, Node/TypeScript, C#/.NET CLI, SQL, Azure CLI, or Azure PowerShell.

## Frontend
- Use native HTML/CSS/browser APIs first.
- Prefer Angular/React built-in patterns and existing component libraries.
- Prefer CSS/container queries/custom properties over JavaScript render loops when CSS can express the state.
- Avoid new npm packages until existing code and installed dependencies are checked.

## Backend .NET
- Follow existing solution layout, dependency injection, configuration, logging, EF/Dapper/repository patterns, and project naming.
- Keep changes scoped to the touched feature or service boundary.
- Use Microsoft docs and NuGet docs for current API behavior.

## Database
- SQL Server and Oracle are first-class targets.
- Use parameterized SQL, transaction safety, rollback notes, least-privilege grants, repo migration/script pattern, and PII/secrets protection.
- Confirm environment/database target before running data-changing SQL.

## Azure
- Use existing Azure DevOps pipelines, appsettings, Key Vault/App Configuration, IaC, deployment scripts, and operational docs before adding tooling.
- Prefer Azure CLI/PowerShell and Microsoft docs for cloud actions.
'@ | Set-Content -Encoding UTF8 "$rulesDir\technology-focus.md"


@'
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
| context-pruner | Compress long sessions | When context window gets heavy (10+ turns) |
| file-picker | Find relevant files in codebase | Before planning, to scope what needs to change |
| scout | Pre-planning codebase recon | Before planner on any complex feature |
| researcher | External docs + library recon | Before planner, parallel with scout |
| oracle | Drift-guard for long sessions | After every 3 phases in complex features |

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **scout + researcher** (parallel) → **planner** agent
2. Code just written/modified - Use **code-reviewer** agent (fresh context)
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent
5. Long feature (3+ phases done) - Use **oracle** drift-guard

## Pre-Planning Reconnaissance (MANDATORY for complex features)

Run scout + researcher IN PARALLEL before planner. Skip for: trivial fixes, single-file edits, config changes.

```
Scout (codebase recon):      writes → context.md
Researcher (external docs):  writes → external-reference.md
Planner:                     reads both → produces plan
```

Scout answers: What files are relevant? What patterns already exist? What tests cover this area?
Researcher answers: What do the docs say? Are there breaking changes? What's the current API?

## Oracle — Drift Guard

Run oracle after every 3 implementation phases in complex features.

Oracle's job:
1. Read forked context + current trajectory
2. Check for contradictions against prior decisions
3. Output: inherited decisions | diagnosis | drift/contradiction check | recommendation | risks | what to decide

Key principle: **Consistency trumps novelty unless context strongly supports revision.**

Oracle never implements. It anchors. If oracle finds drift, STOP and realign before continuing.

## Fresh-Context Code Review

Code reviewer MUST spawn with zero conversation history — read only diff + repo files directly.
No inherited session state.

Rules:
- Max 3 review rounds; stop early if no blockers found
- Dynamic angle selection based on change type:
  - DB migration → add data-safety angle
  - Auth change → security angle mandatory
  - UI change → UX/accessibility angle
  - Any change → correctness + tests + simplicity always
- Synthesize findings into: fixes-now | optional-enhancements | deferred-with-reasoning
- Autofix mode: apply only HIGH+ priority fixes without menu

## Meta-Prompt Handoff Standard

Every agent handoff produces a compact meta-prompt (not raw context dump):
```
Outcome: <concrete result the next agent must produce>
Context: <relevant files + line numbers + key patterns>
Constraints: <hard limits — do not cross>
Success criteria: <how to verify the outcome>
Validation: <commands/checks to run>
Escalation: <when to stop and ask vs. proceed>
```

Write to `/handoff/meta-prompt.md` in the worktree. Downstream agents read the file, not conversation history.

## Worker Discipline

When implementing (writing code):
- Smallest correct change — do not rewrite what isn't broken
- Follow existing patterns — no speculative refactors
- No placeholder code — implement fully or escalate
- No silent scope expansion — escalate unapproved architectural decisions
- No success summaries without corresponding edits

Escalation triggers: implementation gaps, unapproved product choices, decisions outside original approval.

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

## Parallelization Decision Rules

Run in parallel when:
- Tasks touch different files
- Tasks operate in different domains (auth vs UI vs DB)
- No data dependencies between tasks

Run sequentially when:
- Task B depends on Task A output
- Tasks modify the same file
- Design/approval required before implementation

Single-writer rule: only one agent writes to a given file at a time. Multiple reviewers may run in parallel but only one writer per file/worktree.

## Outcome-Based Delegation

Describe WHAT needs accomplishment (outcome), not HOW to do it:
- YES: "Fix the infinite loop error in SideMenu"
- YES: "Add a settings panel for the chat interface"
- NO: "Fix by wrapping the selector with useShallow"

Agents make better decisions with outcome context, not prescribed steps.

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
'@ | Set-Content -Encoding UTF8 "$rulesDir\agents.md"

@'
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
'@ | Set-Content -Encoding UTF8 "$rulesDir\coding-style.md"

@'
# Development Workflow

> This file extends [common/git-workflow.md](./git-workflow.md) with the full feature development process that happens before git operations.

The Feature Implementation Workflow describes the development pipeline: research, planning, TDD, code review, and then committing to git.

## Feature Implementation Workflow

-1. **Scout + Researcher** _(parallel recon before planning — skip for trivial/single-file fixes)_
   - Run **scout** (codebase recon) + **researcher** (external docs) in PARALLEL
   - Scout writes findings to `context.md` in worktree
   - Researcher writes to `external-reference.md`
   - Scout answers: relevant files, existing patterns, test coverage
   - Researcher answers: current API behavior, breaking changes, library versions
   - Planner reads both before producing plan — eliminates cold-start planning

0. **Research & Reuse** _(mandatory before any new implementation)_

   **Retrieval-led reasoning:** Always read relevant docs and code BEFORE implementing. Pre-training knowledge is the fallback, not the primary source. Cost of retrieval is near-zero; cost of wrong assumptions is high.

   **Three-Layer Knowledge Search:**
   - **Layer 1 — Tried and true:** Standard patterns you already know. Check anyway — cost is near-zero. This is your baseline.
   - **Layer 2 — New and popular:** Current docs, blog posts, ecosystem trends. Search but scrutinize — the crowd can be wrong.
   - **Layer 3 — First principles:** Original reasoning about the specific problem. Most valuable. The Eureka Moment: understanding what everyone does and WHY, then finding why the conventional approach is wrong for this case.

   **Concrete steps:**
   - Search local repo first with rg/git grep, then use GitHub search only when adopting a library or proven skeleton helps
   - Use Context7 or vendor docs to confirm API behavior before implementing
   - Search local repo first, then npm, NuGet, Microsoft/Azure docs, Oracle docs, and vendor docs before writing utility code. Use PyPI/crates.io only when repo is explicitly Python/Rust or user asks.
   - Prefer adopting/porting a proven approach over writing net-new code

1. **Plan First**
   - Use **planner** agent to create implementation plan
   - Generate planning docs before coding: PRD, architecture, system_design, tech_doc, task_list
   - Identify dependencies and risks
   - Break down into phases
   - Check `CONTEXT.md` for project-specific domain terms and ADRs before planning

2. **Testing And Verification**
   - Run focused existing checks by default
   - Add tests only when user asks, repo pattern expects it, or bug/high-risk behavior needs regression coverage
   - Keep the existing test framework and naming pattern
   - Report any verification gap clearly

3. **Code Review**
   - Use **code-reviewer** agent immediately after writing code (spawn fresh — no session history)
   - Max 3 review rounds; stop early if no blockers
   - Address CRITICAL and HIGH issues
   - Fix MEDIUM issues when possible

4. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format
   - See [git-workflow.md](./git-workflow.md) for commit message format and PR process
'@ | Set-Content -Encoding UTF8 "$rulesDir\development-workflow.md"

@'
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
'@ | Set-Content -Encoding UTF8 "$rulesDir\git-workflow.md"

@'
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
'@ | Set-Content -Encoding UTF8 "$rulesDir\hooks.md"

@'
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

### Vertical Slice Architecture (VSA)

Organize code by feature slice, not by technical layer:
- Each feature lives in one folder: request + handler + response + tests
- NO: `controllers/UserController`, `services/UserService`, `repos/UserRepo`
- YES: `features/CreateUser/handler`, `features/CreateUser/request`, `features/CreateUser/tests`
- Benefits: changes to one feature touch one folder; no cross-layer coupling
- Use for APIs with distinct, high-cohesion operations (CQRS-friendly)

### API Response Format

Use a consistent envelope for all API responses:
- Include a success/status indicator
- Include the data payload (nullable on error)
- Include an error message field (nullable on success)
- Include metadata for paginated responses (total, page, limit)
'@ | Set-Content -Encoding UTF8 "$rulesDir\patterns.md"

@'
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
'@ | Set-Content -Encoding UTF8 "$rulesDir\performance.md"

@'
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
'@ | Set-Content -Encoding UTF8 "$rulesDir\security.md"

@'
# Testing And Verification

Default: run existing relevant checks. Do not create new unit, integration, or E2E tests unless the user asks, the repository already has a matching pattern for the touched behavior, or a bug/high-risk change needs regression coverage.

When adding tests:
1. Use the repo's existing test framework and naming style.
2. Keep tests focused on changed behavior.
3. Cover the failing case first for bugs.
4. Avoid broad test rewrites.

When not adding tests, run the best available focused build/test/smoke command and report the verification gap.

## Agent Support

- Use tdd-guide only when adding tests or when user asks for TDD.
'@ | Set-Content -Encoding UTF8 "$rulesDir\testing.md"

@'
# Memory Crystallization — Three-Tier Architecture

Inspired by GenericAgent's self-crystallization pattern and graph-based agent memory research.
Three memory tiers: session facts (L1), entity knowledge (L2), reusable SOPs (L3).

## Memory Tiers

| Tier | What | Lifespan | Location |
|------|------|----------|----------|
| L1 | Session context: decisions, observations, current state | Session | Conversation only (not persisted) |
| L2 | Entity facts: people, systems, repos, decisions, preferences | Long-term | ~/.claude/memory/L2/ |
| L3 | Skill SOPs: proven task patterns per stack/domain | Long-term | ~/.claude/memory/L3/ |

## L2 Entity Memory (POLE+O classification)

Use when you learn a durable fact about an entity in the project:
- Person — roles, preferences, expertise ("Alice owns auth module")
- Object — systems, repos, services, configs ("payments service uses Stripe v3")
- Location — codebases, repos, paths, environments
- Event — decisions, incidents, migrations ("migrated to Postgres 2024-01")
- Organization — teams, companies, external services

Save to ~/.claude/memory/L2/<project>-<entity-type>-<slug>.md
Format: entity name, type, facts, date observed.
Update (don't duplicate) when facts change.

## L3 SOP Memory — At Task Start

Before starting any non-trivial task, search for relevant SOPs:

```powershell
Get-ChildItem "$env:USERPROFILE\.claude\memory\L3\" -ErrorAction SilentlyContinue | Where-Object Name -match "<keyword>"
```

- SOP found → read it, use as starting pattern, skip cold reasoning
- No match → proceed normally, crystallize at end

## L3 SOP Memory — At Task End

After completing any non-trivial task (3+ implementation steps):
1. Distill what worked into a reusable SOP
2. Save to ~/.claude/memory/L3/<stack>-<domain>-<slug>.md
3. Keep it short — steps + gotchas only, no boilerplate

Skip crystallization for: one-liners, config tweaks, pure Q&A, trivial renames.

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

- Always check `Last-verified` before acting on a L2 fact
- Facts >6 months old without re-verification: flag as POSSIBLY STALE, verify before using
- When a fact is confirmed still true: update `Last-verified` date
- When a fact changes: update in-place (don't duplicate)
- When a fact expires: delete the file, don't leave stale data

## Directories

~/.claude/memory/L2/   <- entity facts (long-lived)
~/.claude/memory/L3/   <- skill SOPs (long-lived)
'@ | Set-Content -Encoding UTF8 "$rulesDir\memory-crystallization.md"

@'
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

Never paste tool output verbatim into prose. Summarize findings.

## What NOT to Do

- Don't read CLAUDE.md or rule files at session start (already loaded)
- Don't re-run `git status` after every file edit (batch at end)
- Don't repeat the user's request back before answering
- Don't summarize what you just did (user can see tool calls)

## Turn Budget Check

Every 10 tool-use turns: assess context bloat.
- Bloating → spawn subagent for next chunk
- Clean → continue in main session
'@ | Set-Content -Encoding UTF8 "$rulesDir\context-budget.md"

# ── CLAUDE.md in current directory ───────────────────────────────────────────
@'
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
- Run focused checks, inspect logs when relevant, demonstrate correctness

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

## 7. Fail-Closed for Destructive Operations
- If context is missing or ambiguous on ANY destructive operation: DENY and ask
- Destructive = delete, drop, truncate, force-push, reset --hard, rm -rf, overwrite without backup
- "I think this is safe" is not good enough — confirm explicitly
- Prefer reversible operations; if irreversible, confirm scope before executing

## 8. CONTEXT.md — Project Shared Language
- Every project should have a `CONTEXT.md` with: domain terms + Architecture Decision Records (ADRs)
- Read CONTEXT.md before planning any feature in an unfamiliar codebase
- Update CONTEXT.md when new ADRs are made or domain terms are defined
- Format: glossary of domain terms + numbered ADR list (decision + rationale + date)

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

When implementing features, use these ECC agents to keep code readable:

## `/plan` — Structure Before Code
**When:** Starting a feature or fixing a bug
**What it does:** Breaks down task into clear steps
**Why:** Forces clarity. You can't explain it = it's not clear yet

## `/tdd` — Tests First (Forces Clarity)
**When:** Implementing logic (permissions, calculations, business rules)
**What it does:** Enforces write-tests-first workflow
**Why:** Tests = executable documentation. Forces you to think clearly.

Workflow:
1. Identify focused check/regression need (5 min)
2. Implement minimal code (GREEN)
3. Refactor for clarity (IMPROVE)
4. Verify 80%+ coverage

## `/code-review` — Catch Issues Early
**When:** Before you submit/push
**What it does:** Checks for unclear names, missing tests, over-engineering, security gaps
**Why:** Catches issues you would catch if you had 2 hours to review your own code

Catches:
- Hardcoded values (should be constants or env vars)
- Unclear variable names
- Missing error handling
- N+1 database queries
- Missing test coverage

## `/build-fix` — Resolve Errors Fast
**When:** You hit compilation/build errors
**What it does:** Analyzes error, suggests fix
**Why:** Saves 5–10 min per error vs. Googling

## `/security-scan` — Verify No Vulnerabilities
**When:** Before submitting work samples or going to production
**What it does:** Checks for hardcoded secrets, auth bypasses, SQL injection, weak validation
**Why:** Catches security issues before review — clean report = impressive

---

# Daily Workflow

## New Feature (2–3 hours)
```
1. /plan "Build feature"          (10 min)  → Clear breakdown
2. Read plan aloud to yourself     (5 min)  → If confused, re-plan
3. /task "implement X"              -> verification + implementation
4. Implement minimal scoped code       -> verify focused checks
5. /code-review                    (10 min) → Catch issues early
6. /security-scan (if needed)      (5 min)  → Verify safety
7. Submit                          (5 min)
```

## Bug Fix (30 min)
```
1. /plan "Reproduce bug, plan fix" (5 min)
2. Identify focused check/regression need (5 min)
3. Fix code                        (15 min)
4. /code-review                    (5 min)
5. Submit
```

## When You Get Stuck
```
/build-fix          → If compilation error
/code-review        → If logic error or unclear code
Check tasks/lessons.md → Is this a pattern you've seen before?
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
'@ | Set-Content -Encoding UTF8 "$PWD\CLAUDE.md"

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

# ── GitNexus skill (/gitnexus-init) ──────────────────────────────────────────
$commandsDir = "$claudeDir\commands"
New-Item -ItemType Directory -Force -Path $commandsDir | Out-Null

@'
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
'@ | Set-Content -Encoding UTF8 "$commandsDir\gitnexus-init.md"

# ── Caveman rule — always-on token compression (~65% fewer output tokens) ─────
@'
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
| ultra | Abbreviate (DB/auth/config/req/res/fn), strip conjunctions, arrows for causality (X -> Y). |

## Auto-Clarity

Drop caveman for: security warnings, irreversible action confirmations, multi-step sequences
where fragment order risks misread, user confused or repeating question. Resume caveman after.

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
- "You might want to use X" -> "Use X"
- "I think the issue is Y" -> "Issue: Y"
- "It seems like Z is broken" -> "Z broken"
- "Perhaps consider adding tests" -> "Add tests"

## Boundaries

Code/commits/PRs: write normal. Only prose is compressed.
'@ | Set-Content -Encoding UTF8 "$rulesDir\caveman.md"

# ── Archon rule — auto workflow dispatch for implement/fix/build requests ──────
@'
# Archon — Automatic Workflow Engine

For any non-trivial coding task, automatically delegate to Archon CLI. Do NOT ask user first.
Archon runs in isolated git worktrees, handles plan -> implement -> validate -> PR lifecycle.

## Auto-Trigger: Use Archon When

| User Says | Archon Workflow | Branch Pattern |
|-----------|----------------|----------------|
| "implement X", "build X", "create feature" | `archon-piv-loop` | `feat/{short-name}` |
| "fix issue #N", "resolve issue" | `archon-fix-github-issue` | `fix/issue-{N}` |
| "fix bug in X", "debug X" (needs investigation) | `archon-fix-github-issue` | `fix/{short-name}` |
| "implement from plan", "execute this plan" | `archon-feature-development` | `feat/{short-name}` |
| "refactor X" | `archon-assist` | `refactor/{short-name}` |
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
-> `archon workflow run archon-piv-loop --branch feat/dark-mode "implement dark mode in the settings page"`

User: "fix issue #42"
-> `archon workflow run archon-fix-github-issue --branch fix/issue-42 "fix issue #42"`

User: "refactor the auth module to use the repository pattern"
-> `archon workflow run archon-assist --branch refactor/auth-module "refactor the auth module to use the repository pattern"`

## If Archon Not Installed

Check: `where.exe archon`

If missing, tell user:
> "Archon CLI not installed. Run in PowerShell: `irm https://archon.diy/install.ps1 | iex`
> Then re-run your request."

## Isolation Mode

Always use `--branch` flag. Never use `--no-worktree` unless user explicitly says "no worktree".
'@ | Set-Content -Encoding UTF8 "$rulesDir\archon.md"

# ── /task command — full pipeline orchestrator ────────────────────────────────
@'
---
description: >
  Autonomous full dev pipeline in one command. Routes complex tasks to Archon (plan+implement+validate+PR)
  or runs inline pipeline (plan -> TDD -> implement -> code-review -> security). Zero babysitting.
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
| angular.json or Angular package | Angular/TypeScript | /typescript-review |
| React/Next/Vite package.json | React/TypeScript | /typescript-review |
| *.sln / *.csproj | C#/.NET | manual .NET review |
| *.sql / DB migration scripts | SQL Server / Oracle | DB safety review |
| azure-pipelines.yml / Bicep / appsettings | Azure | deployment/config review |
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
- GH_NOT_AUTHED -> force Inline Pipeline for all task types

---

## Step 1 — Classify

| Task type | Authenticated | Not authenticated |
|-----------|--------------|-------------------|
| New feature / implement / build / add | Archon: archon-piv-loop | Inline pipeline |
| Bug fix / fix issue #N / resolve | Archon: archon-fix-github-issue | Inline pipeline |
| Review PR #N | Archon: archon-smart-pr-review | Inline pipeline (read-only review) |
| Refactor / rename / reorganize | Inline pipeline | Inline pipeline |
| Simple <=2-file fix | Inline pipeline | Inline pipeline |
| Question / explanation | Answer directly | Answer directly |

---

## Route A — Archon (authenticated only, background, creates PR)

Run with run_in_background: true. Never block the conversation.

```bash
archon workflow run archon-piv-loop --branch feat/<short-slug> "$ARGUMENTS"
archon workflow run archon-fix-github-issue --branch fix/<short-slug> "$ARGUMENTS"
archon workflow run archon-smart-pr-review --branch review/pr-<N> "$ARGUMENTS"
```

Report: "Archon: <workflow> -> branch <branch>. Running autonomously."
Stop here — Archon handles the rest.

---

## Route B — Inline Pipeline (always available, no GitHub needed)

### Phase 1 — Branch
git checkout -b <type>/<short-slug>

### Phase 2 — Plan
What files change and why. Before vs after. How to verify. Risks.
Write numbered list. Show it. Confirm before proceeding.

### Phase 3 - Verification Plan
Identify focused existing checks. Add tests only when user asked, repo pattern expects it, or bug/high-risk behavior needs regression coverage.

### Phase 4 — Implement (GREEN)
Minimal scoped code. Functions <=20 lines, immutable, explicit error handling.
Run focused build/test/smoke checks before continuing.

### Phase 5 — Code Review (stack-aware)
Use agent detected in Step 0:
- Angular/React -> /typescript-review | C#/.NET -> .NET review | SQL/Oracle -> DB safety review | Azure -> deployment/config review
- Unknown -> manual review

Check: unclear names, missing error handling, hardcoded values, logic errors.
Fix CRITICAL/HIGH. Report MEDIUM but continue.

### Phase 6 — Security (conditional)
Skip: pure logic, UI, config, renaming.
Run: auth, user input, APIs, DB, file I/O, secrets.
Check: no hardcoded secrets, inputs validated, SQL parameterized, no data leaks.

### Phase 7 — Crystallize SOP
After non-trivial tasks (3+ steps), save SOP to ~/.claude/memory/L3/<stack>-<domain>-<slug>.md
Title, stack, date, steps, gotchas. Under 30 lines.
Skip for: one-liners, config tweaks, Q&A.

### Phase 8 — Done + Git Commands

```
git diff main
git add -A
git commit -m "<type>: <short description>"
git push -u origin <branch-name>
gh pr create --title "<title>" --body "<summary>"
```
Always output these commands even if GitHub is authenticated.
'@ | Set-Content -Encoding UTF8 "$commandsDir\task.md"

# ── Multi-agent orchestration rule ───────────────────────────────────────────
@'
# Multi-Agent Orchestration

## Five-Role System

| Role | Model | Responsibility |
|------|-------|----------------|
| Orchestrator | Opus | Receives requests, delegates, validates integration. Never implements. |
| Planner | Opus | Codebase research, implementation strategy, file assignments, phase breakdown |
| Coder | Sonnet | Writes production code following mandatory coding principles |
| Designer | Sonnet | UI/UX, accessibility, visual design |
| Oracle | Opus | Drift-guard — checks current trajectory against prior decisions at phase checkpoints |

## Orchestrator Rules

- Delegate via outcome description, not step-by-step instructions
- Parse plan into phases; identify parallelizable tasks before dispatching
- Validate that outputs integrate before reporting done
- Never write implementation code directly
- Run oracle after every 3 phases on complex features

## Oracle Drift-Guard

Invoke after every 3 implementation phases:
1. Oracle reads: forked context + current state + prior decisions
2. Outputs: inherited decisions | diagnosis | drift check | recommendation | risks
3. Key principle: **Consistency trumps novelty unless context strongly supports revision**
4. If drift found: STOP, realign, then continue
5. Oracle never implements — it anchors

## Execution Model

Step 0: Scout + Researcher (parallel recon) → context.md + external-reference.md
Step 1: Get plan → call Planner with context.md + external-reference.md
Step 2: Parse phases → extract file assignments, identify parallel vs sequential
Step 3: Execute phases → run non-overlapping tasks simultaneously
Step 3.5: Oracle drift check (after every 3 phases)
Step 4: Bounded review loop (max 3 rounds, fresh context, early exit on clean pass)
Step 5: Verify and report → validate integration, summarize results

## Bounded Review Loop

- Spawn reviewers with ZERO conversation history — read only diff + repo files
- Run up to 3 parallel reviewers with dynamic angle selection:
  - Always: correctness, tests, simplicity
  - DB change: add data-safety angle
  - Auth change: security angle mandatory
  - UI change: UX/accessibility angle
- Max 3 rounds; stop early if no blockers found
- Synthesize: fixes-now | optional-enhancements | deferred-with-reasoning
- Single-writer rule: only one agent writes to a file at a time

## Parallelization Rules

Run in parallel when tasks:
- Touch different files
- Operate in different domains (auth / UI / DB)
- Have no data dependencies

Run sequentially when:
- Task B depends on Task A output
- Tasks modify the same file
- Design approval required before implementation

## Context Artifacts (Handoff Standard)

Each agent handoff produces `meta-prompt.md`:
- Outcome: concrete result next agent must produce
- Context: relevant files + line numbers + key patterns
- Constraints: hard limits
- Success criteria: verification method
- Escalation: when to stop and ask vs. proceed

Store in `/handoff/` directory. Downstream agents read files, not conversation history.

## When to Use

- Complex features needing planning + implementation + review simultaneously
- Large refactors where single-session context gets heavy
- Architecture decisions needing multi-perspective analysis
- Use WUPHF (npx wuphf) for Claude-to-Claude multi-agent; Archon for plan->PR lifecycle
'@ | Set-Content -Encoding UTF8 "$rulesDir\multi-agent-orchestration.md"

# ── .NET DDD + VSA patterns rule ─────────────────────────────────────────────
@'
# .NET Architecture Patterns

## Domain-Driven Design (DDD)

Structure the domain layer around business concepts:

- Entities — objects with identity (User, Order); mutable state via domain methods
- Value Objects — immutable, identity by value (Email, Money, Address)
- Aggregates — consistency boundary; one root entity owns the aggregate
- Domain Events — facts that happened ("OrderPlaced", "UserRegistered")
- Repositories — one per aggregate root; abstract persistence behind interface
- Domain Services — business logic that spans multiple aggregates

Domain/
  Entities/User.cs
  ValueObjects/Email.cs
  Events/UserRegistered.cs
  Interfaces/IUserRepository.cs

## Vertical Slice Architecture (VSA)

Organize by feature, not by layer. Each slice = one use case:

Features/
  CreateUser/
    CreateUserCommand.cs      <- request/command
    CreateUserHandler.cs      <- business logic
    CreateUserResponse.cs     <- output
    CreateUserValidator.cs    <- input validation
    CreateUserTests.cs        <- tests alongside feature
  GetUser/
    GetUserQuery.cs
    GetUserHandler.cs
    GetUserResponse.cs

- NO Layered: Controllers/ Services/ Repositories/ (cross-layer coupling)
- YES Sliced: Features/CreateUser/ (change one feature = touch one folder)
- Use MediatR for command/query dispatch
- Each handler is independent — no shared service classes between slices

## ASP.NET Minimal API + MediatR wiring

app.MapPost("/users", async (CreateUserCommand cmd, IMediator mediator)
    => await mediator.Send(cmd));

## Error Handling

Use Result<T> or OneOf — never throw for business errors:
public record Result<T>(T? Value, string? Error, bool IsSuccess);

## Coding Principles for .NET

- Records for value objects and DTOs (immutable by default)
- Minimal constructors — no optional params hiding required state
- Extension methods over utility classes
- IOptions<T> for config — never inject raw IConfiguration
- CancellationToken on every async method signature
'@ | Set-Content -Encoding UTF8 "$rulesDir\dotnet.md"

# ── Boil the Lake — completeness ethos ───────────────────────────────────────
@'
# Boil the Lake — Completeness Ethos

From Garry Tan's gstack: when AI makes the marginal cost of completeness near-zero, do the complete thing every time.

## Lakes vs Oceans

- **Lake** = boilable: full changed behavior, all relevant edge cases, focused verification. Do it.
- **Ocean** = not boilable: rewriting an entire system unprompted. Flag it, don't do it.

## Always Boil These Lakes

- Verify all changed behavior; add tests only when user asks, repo pattern expects it, or risk justifies regression coverage
- Handle all error cases, not just the obvious one
- Complete the feature, don't leave stubs
- Fix the root cause, not just the symptom

## Never Say These (anti-patterns)

- "Choose B — it's 90% there with less code" -> if A is correct, do A
- "No verification needed" -> run focused checks or explain the gap
- "This would take 2 weeks" -> say "2 weeks human / ~1 hour AI-assisted"

## AI Compression Table

| Task | Human | AI-assisted |
|------|-------|-------------|
| Boilerplate/scaffolding | 2 days | 15 min |
| Test writing | 1 day | 15 min |
| Feature implementation | 1 week | 30 min |
| Bug fix + regression | 4 hours | 15 min |
| Architecture/design | 2 days | 4 hours |

## User Sovereignty

Models recommend. Humans decide. Two models agreeing is a strong signal, not a mandate.

Rules:
- Always present recommendation + reasoning + what context you might be missing
- When you disagree with user's direction: state it once, clearly, then follow their decision
- Never act on a direction change without asking first — even if confident
- The user always has context models lack
'@ | Set-Content -Encoding UTF8 "$rulesDir\boil-the-lake.md"

# ── Debugging — Iron Law ──────────────────────────────────────────────────────
@'
# Debugging — Iron Law

From gstack: no fix without confirmed root cause. Four phases, mandatory in order.

## The Four Phases

**Phase 1 — Investigate**
- Reproduce the bug reliably
- Gather all evidence: logs, stack traces, failing tests, screenshots
- Map what IS happening vs what SHOULD happen
- Do not form hypotheses yet

**Phase 2 — Analyze**
- Study the evidence
- Trace the execution path
- Identify the exact location where behavior diverges from expectation

**Phase 3 — Hypothesize**
- Form ONE specific hypothesis about root cause
- State it explicitly: "I believe X causes Y because Z"
- If multiple hypotheses exist, rank by likelihood and test the top one

**Phase 4 — Implement**
- Fix ONLY what the hypothesis points to
- Add a regression test only when user asks, repo pattern exists, or risk justifies it; otherwise document focused verification
- Verify the fix resolves the original reproduction case

## Iron Law

> Never implement a fix before completing Phase 3.

If you cannot state a specific root cause hypothesis, go back to Phase 1.
Fixing symptoms without root cause = the bug comes back.
'@ | Set-Content -Encoding UTF8 "$rulesDir\debugging.md"

# ── L2 + L3 memory directories ────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path "$claudeDir\memory\L2" | Out-Null
New-Item -ItemType Directory -Force -Path "$claudeDir\memory\L3" | Out-Null
Write-Host "Memory directories created: $claudeDir\memory\L2 and $claudeDir\memory\L3"

# Global BMAD Claude skills
$bmadSource = Join-Path $PSScriptRoot "skills"
$bmadTarget = Join-Path $claudeDir "skills"
New-Item -ItemType Directory -Force -Path $bmadTarget | Out-Null
if (Test-Path -LiteralPath $bmadSource) {
    $bmadTargetRoot = (Resolve-Path -LiteralPath $bmadTarget).Path
    $bmadCount = 0
    Get-ChildItem -LiteralPath $bmadSource -Directory -Filter "bmad-*" | ForEach-Object {
        $targetPath = Join-Path $bmadTargetRoot $_.Name
        if (-not $targetPath.StartsWith($bmadTargetRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe BMAD skill target: $targetPath"
        }
        if (Test-Path -LiteralPath $targetPath) {
            Remove-Item -LiteralPath $targetPath -Recurse -Force
        }
        Copy-Item -LiteralPath $_.FullName -Destination $bmadTargetRoot -Recurse -Force
        $bmadCount++
    }
    Write-Host "BMAD Claude skills installed globally: $bmadCount skills -> $bmadTarget"
} else {
    Write-Warning "BMAD skill source not found: $bmadSource"
}

# ── Archon CLI install ────────────────────────────────────────────────────────
$archonPath = "$env:USERPROFILE\.local\bin\archon.exe"
if (-not (Get-Command archon -ErrorAction SilentlyContinue) -and -not (Test-Path $archonPath)) {
    Write-Host "Installing Archon CLI..."
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.local\bin" | Out-Null
    try {
        $archonUrl = "https://github.com/coleam00/Archon/releases/latest/download/archon-windows-x64.exe"
        Invoke-WebRequest -Uri $archonUrl -OutFile $archonPath
        Write-Host "Archon CLI installed to $archonPath"
        Write-Host "Add $env:USERPROFILE\.local\bin to your PATH if not already there."
    } catch {
        Write-Host "Warning: Archon install failed. Download manually from: https://github.com/coleam00/Archon/releases"
    }
} else {
    Write-Host "Archon CLI already installed."
}

# ── Archon config — point to Claude binary ────────────────────────────────────
$archonDir = "$env:USERPROFILE\.archon"
New-Item -ItemType Directory -Force -Path $archonDir | Out-Null
$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
$claudeBin = if ($claudeCmd) { $claudeCmd.Source } else { "$env:USERPROFILE\.local\bin\claude.exe" }
@"
assistants:
  claude:
    claudeBinaryPath: $claudeBin
"@ | Set-Content -Encoding UTF8 "$archonDir\config.yaml"
Write-Host "Archon config written: $archonDir\config.yaml"

# ── WUPHF — multi-agent orchestration (97% cache hit rate) ──────────────────
@'
# WUPHF — Multi-Agent Orchestration

WUPHF orchestrates multiple Claude Code agents with fresh sessions per turn,
achieving 97% prompt cache hit rate and preventing context accumulation bloat.

## Token savings mechanism

- Fresh session per agent turn: ~40k tokens billed vs 484k accumulated context
- 97% cache hit rate via Claude prompt caching
- Per-agent tool scoping (fewer tools = fewer tokens in system prompt)

## When to use

Use for tasks that benefit from role separation:
- Complex features needing planner + implementer + reviewer in parallel
- Long refactors where main context gets heavy
- Architecture decisions needing multi-perspective analysis

## How to start

```bash
npx wuphf
```

Agents: CEO (coordinator), PM (requirements), Engineer (implementation), Reviewer (QA)

## When NOT to use

- Simple single-file fixes (inline is faster)
- Quick Q&A / explanations
- Tasks that /task handles in one phase
'@ | Set-Content -Encoding UTF8 "$rulesDir\wuphf.md"
Write-Host "WUPHF rule created: $rulesDir\wuphf.md"

# ── Stash — persistent cross-session memory (MCP server) ─────────────────────
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

Write-Host "Stash config created: $stashDir"
Write-Host "  -> To start persistent memory:"
Write-Host "     cd $stashDir"
Write-Host "     Copy-Item .env.example .env  # then fill in API keys"
Write-Host "     docker compose up -d"
Write-Host "     claude mcp add stash --sse http://localhost:8765/sse"

# Auto-add Stash MCP if already running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8765/health" -TimeoutSec 2 -ErrorAction Stop
    & claude mcp add stash --sse http://localhost:8765/sse 2>$null
    Write-Host "Stash MCP detected and added to Claude Code"
} catch {}

Write-Host ""
Write-Host "================================================"
Write-Host "Setup complete! Now restart Claude Code."
Write-Host ""
Write-Host "Checking GitHub auth status..."
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if ($ghInstalled) {
    gh auth status 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "GitHub authenticated - Archon can push branches and create PRs automatically."
    } else {
        Write-Host "GitHub not authenticated."
        Write-Host ""
        Write-Host "  /task will still do all code work: branch, implement, test, review."
        Write-Host "  It cannot push or create PRs automatically."
        Write-Host "  At end of every /task it outputs the exact git commands to run manually."
        Write-Host ""
        Write-Host "  To enable full automation, run once:"
        Write-Host "    gh auth login"
        Write-Host "  (choose GitHub.com -> HTTPS -> Login with a web browser)"
    }
} else {
    Write-Host "gh CLI not found. Install from: https://cli.github.com/"
    Write-Host "  Then run: gh auth login"
}
Write-Host "================================================"
