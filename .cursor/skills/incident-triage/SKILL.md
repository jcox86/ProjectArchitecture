---
name: incident-triage
description: Triage production/staging incidents for this Azure-first SaaS template using logs/traces/metrics (OpenTelemetry + Azure Monitor) and platform signals (Front Door, Container Apps, Postgres, Redis, Storage). Use when debugging outages, errors, latency spikes, or stuck queues.
module: cursor.skills.incidentTriage
purpose: Provide a repeatable incident investigation workflow aligned with the template’s observability and Azure platform choices.
exports:
  - workflow: triage_incident
patterns:
  - observability
  - azure_monitor
  - progressive_narrowing
notes:
  - Prefer mitigation first (reduce blast radius), then deeper diagnosis.
---

# Incident triage (template workflow)

## 0) Capture the basics (2 minutes)

- What is the symptom? (errors, latency, timeouts, stuck background jobs)
- What is the scope? (single tenant vs many; admin vs product)
- When did it start? Any recent deploys/infra changes?
- Collect: tenant identifier (if applicable), request IDs/correlation IDs, time window.

## 1) Edge first: Front Door / WAF (if traffic is affected)

- Validate origin health probes and routing rules.
- Check WAF blocks/false positives for the affected paths/hosts.
- Confirm correct hostnames: `admin.<root>` vs `*.<root>` routes (template baseline).

## 2) Service health: Azure Container Apps

- Identify which service is impacted (API / Worker / Admin UI).
- Check revision status and recent rollout changes (blue/green, traffic weights).
- Check replica health and restarts; look for startup failures/config issues.

## 3) Work queues (Worker)

- Check queue depth trends and dequeue attempts.
- Confirm poison queue behavior is working (messages moved after N attempts).
- Look for idempotency/outbox failures causing repeated work.

## 4) Dependencies

- PostgreSQL: connection exhaustion, auth failures, slow queries, lock contention.
- Redis: availability, timeouts, saturation (used for caching like ABAC attributes/routing).
- Storage: throttling, auth failures, queue service issues.

## 5) Use traces/logs/metrics to narrow quickly

- Start from the failure surface (HTTP 5xx, timeouts, retry storms).
- Pivot by correlation ID/trace ID and tenant context.
- Identify the first failing dependency call and error class.

## 6) Mitigation playbook (choose the smallest safe lever)

- Roll back traffic to previous healthy revision (ACA weighted traffic).
- Temporarily scale replicas up/down (respect max caps).
- Disable high-risk features via configuration/flags (when available).
- Drain/disable worker processing if it’s amplifying damage (with a documented plan).

## 7) After-action (minimum)

- Write a short summary: timeline, root cause, mitigation, follow-ups.
- Add/adjust alerts and dashboards for the missing signal.

