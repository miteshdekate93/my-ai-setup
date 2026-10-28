# Decision Framework

## Options Matrix

Score each criterion 1-5 (5 = best). Weights must sum to 100 and be agreed with the user before scoring. Show raw scores and reasoning, not just totals.

| Criterion | Weight | Option A | Option B | Option C |
|-----------|--------|----------|----------|----------|
| Requirement fit (functional + NFR) | 25 | | | |
| Delivery risk / complexity | 15 | | | |
| Total cost (build + run + people, 3-yr) | 15 | | | |
| Security / compliance | 15 | | | |
| Operability (deploy, monitor, support) | 10 | | | |
| Team skill / hiring | 10 | | | |
| Lock-in / exit cost | 5 | | | |
| Time to value | 5 | | | |

A weighted score is a conversation aid, not the answer. If the winner surprises you, the weights are wrong or a criterion is missing; say so.

## Always Include These Options

1. **Extend/keep existing** (cost of change vs cost of replacement)
2. **Cheapest viable** (minimum that meets must-have NFRs)
3. **Recommended**
4. **Strategic** (optional: higher cost, better long-term position)

## Build vs Buy vs Reuse

Order: reuse in-estate platform -> buy/SaaS -> adopt OSS -> build. Build only when it differentiates the business or nothing fits. Count: integration effort, customization limits, data residency, licensing growth, vendor viability, exit path, support SLA.

## Total Cost Model (state assumptions, give ranges)

- One-off: design, build, migration, training, parallel run, decommission
- Run: compute/storage/network/egress, licences (SQL Server/Oracle per core, Azure Hybrid Benefit/reservations), support, monitoring/log ingestion, backup/DR, security tooling
- People: on-call, upgrades, skills gap, hiring
- Risk-adjusted: incident cost, compliance penalty, delay cost
- Sensitivity: which 2-3 inputs move the total most? Show best/expected/worst.

Never fabricate prices. Pull current Azure pricing from vendor pages/calculator, cite date, or mark as ASSUMPTION with a range.

## Reversibility Test

Classify each decision:
- **Two-way door** (cheap to reverse): decide fast, document briefly.
- **One-way door** (data model, identity provider, cloud/DB platform, public API contract): slow down, more evidence, full ADR, stakeholder sign-off.

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner | Trigger/early signal |
|----|------|-----------|--------|------------|-------|----------------------|

Rank by likelihood x impact. Anything high/high needs a mitigation in the roadmap, not just a note.

## Security Design Questions

- Who/what are the identities (users, services)? How authenticated (Entra ID, managed identity, mTLS)? How authorized (RBAC/ABAC, claims, row-level security)?
- Data classification, PII, encryption at rest/in transit, key ownership (Key Vault, CMK)?
- Network: public endpoints, private endpoints, WAF, egress control, segmentation?
- Secrets: none in code/config; rotation path?
- Audit: who changed/read what, retention, tamper resistance?
- Threat model top 5 (STRIDE) and abuse cases; supply-chain and third-party risk?

## Operability Questions

- SLOs and error budget? Alert on symptoms or causes?
- Logs/metrics/traces correlated by request id? Dashboards exist before go-live?
- Deploy: pipeline, blue/green or canary, DB migration strategy, rollback time?
- Runbooks, on-call owner, DR drill cadence, RPO/RTO proven or assumed?
- Capacity/cost guardrails: budgets, quotas, autoscale limits?

## "What breaks at 10x?" Review Prompts

Load x10, data x10, users x10, teams x3, integrations x3: first bottleneck, first cost cliff, first operational pain, first consistency/ownership conflict. Name the trigger metric that forces the next architecture step.
