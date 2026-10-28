# Default Stack Guidance (Azure / .NET / Angular-React / SQL Server-Oracle)

Starting points, not mandates. Verify current service capabilities, limits, SKUs, and pricing on Microsoft Learn before recommending; cite source and date.

## Compute Selection

| Need | Default | Move up when |
|------|---------|--------------|
| Standard web/API | App Service (zone-redundant, deployment slots) | many services, custom networking, sidecars -> Container Apps/AKS |
| Event/queue work, glue | Azure Functions (Flex/Premium for VNet/cold start) | long-running/stateful -> Durable Functions or Container Apps jobs |
| Containers, moderate scale | Container Apps | strict k8s control/ecosystem -> AKS |
| Legacy IIS/.NET Framework | IIS on VM / App Service (Windows) | modernize per strangler plan |

AKS only with a platform team and real need. Microservices only for independent scaling/deploy/ownership; start modular monolith (vertical slices).

## Data

- **Azure SQL / SQL Server**: default relational. Use row-level security, TDE, Always Encrypted for sensitive columns, elastic pools for many small DBs, read replicas/geo-replication for DR. Check licensing (Hybrid Benefit, reserved capacity).
- **Oracle**: keep where Oracle-specific features/licensing lock-in justify; plan integration via ODP.NET, Oracle Database@Azure, or replicate/CDC; flag licence cost per core and exit complexity.
- **Cosmos DB / Redis / Search**: only for access patterns relational cannot serve (global distribution, sub-ms cache, full-text). State the access pattern in the ADR.
- Define system of record per entity. Avoid shared databases between services. Plan migrations (EF migrations/DACPAC/Flyway) in CI with backward-compatible expand/contract changes.

## Messaging and Integration

- Service Bus (queues/topics, sessions, DLQ) for business messaging; Event Grid for reactive events; Event Hubs for high-volume telemetry.
- Design for at-least-once: idempotent consumers, outbox pattern, DLQ handling, poison message runbook.
- API: REST + OpenAPI, versioning strategy, pagination, ProblemDetails errors, rate limits via APIM when multiple consumers/partners.
- Sync calls need timeouts, retries with jitter, circuit breakers (Polly / resilience pipelines), bulkheads.

## Identity and Security

- Entra ID (OIDC/OAuth2) for users; managed identities for service-to-service; no secrets in code.
- Key Vault for secrets/keys; App Configuration for settings/feature flags; reference via managed identity.
- Private endpoints + VNet integration for data stores; Front Door/App Gateway + WAF at the edge.
- Defender for Cloud, policy as code (Azure Policy), diagnostic logs to Log Analytics with retention matching compliance.
- Review against OWASP ASVS/Top 10 and Microsoft Well-Architected Security pillar.

## .NET Application Architecture

- Modular monolith with vertical slices by default; DDD only where the domain is complex. Clean boundaries between modules (public contracts, no cross-module DB access).
- Minimal APIs or controllers consistently; MediatR optional (do not add for ceremony). `IOptions<T>`, `CancellationToken` everywhere, `ILogger` structured logging, `HttpClientFactory`, health checks (liveness/readiness).
- EF Core for CRUD, Dapper for hot read paths; avoid leaking entities through APIs; explicit transaction boundaries.
- Result types for business errors; exceptions for exceptional cases.

## Frontend

- Angular (enterprise, large teams, opinionated) or React (flexibility) per existing estate; do not mix without reason. TypeScript strict. State: built-in/signals/query libs before adding global stores. BFF pattern when SPA needs token isolation or aggregation. Accessibility and performance budgets as NFRs.

## Delivery and Operations

- Azure DevOps: multi-stage YAML, environments with approvals, artifact promotion (build once, deploy many), IaC (Bicep/Terraform) in the same pipeline, DB migration step, smoke tests, automated rollback or slot swap.
- Observability: Application Insights/OpenTelemetry, correlation ids, SLO dashboards, actionable alerts; cost budgets and tag policy from day one.
- Environments: dev/test/stage/prod parity via IaC; data masking for non-prod.

## Resilience and DR

Define RPO/RTO first, then pick: zone redundancy (default for prod), backups + PITR, geo-replication/failover groups, paired-region strategy, DR drills. Test restore, not just backup. Document dependency failure behavior (degrade, queue, fail fast).

## Cost Guardrails

Right-size, autoscale with ceilings, reservations/savings plans for steady load, Hybrid Benefit, dev/test pricing, log ingestion caps, egress awareness, storage tiers/lifecycle. Include run-cost per environment in every proposal.

## Common Anti-Patterns to Challenge

Premature microservices; shared DB between services; synchronous call chains across 4+ services; "event-driven" without idempotency/DLQ; custom auth; secrets in pipelines variables; one giant resource group/subscription; no cost owner; missing rollback for DB changes; designing for hypothetical 100x scale; vendor-neutral abstraction layers with no second vendor.
