<!--
module: docs.operations.observability
purpose: Document observability conventions for logging, tracing, metrics, and dashboards.
exports:
  - doc: observability_conventions
patterns:
  - opentelemetry
  - serilog
  - health_checks
-->
# Observability conventions

This repo standardizes on OpenTelemetry for traces/metrics and Serilog for structured logs.
Correlation identifiers (tenant/user/trace) are captured consistently so logs, traces, and metrics
can be joined in Azure Monitor.

## Conventions

- **Service defaults**: API/Worker use the shared ServiceDefaults project for OpenTelemetry,
  Serilog, and health checks.
- **Correlation header**: inbound HTTP requests accept `X-Correlation-ID`; if absent, one is
  generated and returned in the response header.
- **Standard log fields**:
  - `correlationId` (from header or generated)
  - `tenantId` (resolved from subdomain)
  - `userId` (from identity claims when authenticated)
  - `traceId` (OpenTelemetry trace)

## OpenTelemetry exporters

Use one of the following:

- **OTLP**: set `OTEL_EXPORTER_OTLP_ENDPOINT` for local or self-hosted collectors.
- **Azure Monitor**: set `APPLICATIONINSIGHTS_CONNECTION_STRING` to export to Application Insights.

## Admin UI logging

The Admin UI ships safe, structured client logs to the API at
`POST /api/admin/telemetry/logs`. Logs are sanitized (token and email redaction,
truncation) and enriched with `correlationId`, `userId`, and optional `tenantId`
before they are sent.

## Health checks

- `GET /health` is the readiness endpoint (all checks must pass).
- `GET /alive` is the liveness endpoint (only the self-check must pass).
- Endpoints are exposed by default in development and can be enabled elsewhere with
  `HealthChecks:Expose=true`.

## Dashboards (Azure Monitor)

Create a workbook or dashboard with these panels:

- **API request rate, latency (p50/p95), error rate** by route and status code.
- **Dependency duration/error rate** for Postgres, Redis, and Storage Queues.
- **Worker throughput**: outbox dispatch counts and failures.
- **Queue depth/lag** for storage queues (work + poison).
- **Health check status** for API and Worker.

Recommended dimension filters:

- `service.name`
- `deployment.environment`
- `tenant.id` (when investigating tenant-specific issues)
- `correlation.id` (for deep-dive trace/log correlation)
