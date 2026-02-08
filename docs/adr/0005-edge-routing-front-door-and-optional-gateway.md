<!--
module: docs.adr.edgeRouting
purpose: Record the decision to use Azure Front Door as the Internet edge and keep an internal gateway optional (YARP) rather than default.
exports:
  - decision: front_door_as_edge_waf_and_router
  - decision: optional_gateway_yarp_behind_front_door
patterns:
  - adr
  - edge_routing
  - waf
-->

# ADR 0005: Edge routing with Front Door (optional gateway)

- **Status**: Accepted
- **Date**: 2026-02-04
- **Deciders**: Template maintainers

## Context

We need an Internet edge that provides:

- WAF and TLS termination
- Host/path routing for admin and tenant traffic
- A stable public surface for Container Apps origins
- A parameterized tier (Standard for dev/smaller, Premium for prod/hardening)

A full gateway/proxy layer (e.g., YARP) can add operational complexity and can become a new place for business logic or auth boundary mistakes if introduced too early.

## Decision

1. **Azure Front Door is the default Internet edge**
   - Use **Azure Front Door Standard/Premium** (tier parameterized by environment).
   - Enable WAF (Premium by default in production).

2. **Routing rules**
   - `admin.<rootDomain>`:
     - `/*` → Admin UI origin
     - `/api/*` → API origin
     - Rationale: Admin UI remains same-origin with its API calls (avoid CORS complexity).
   - `*.<rootDomain>` (tenant subdomains):
     - `/api/*` → API origin
     - `/*` → API origin (baseline template includes no product UI by default)

3. **No gateway by default**
   - Traffic routes directly from Front Door to the API/Admin UI Container Apps.

4. **Gateway is optional**
   - If needed, add a dedicated **Gateway** service (e.g., YARP) **behind** Front Door.
   - Keep it thin: routing/transforms/correlation headers and basic request shaping; **no tenant/business logic**.
   - Maintain explicit auth boundaries to avoid accepting admin tokens on product routes (and vice versa).

## Decision drivers

- Keep the baseline simple and reliable
- Make WAF and edge concerns explicit and centralized (Front Door)
- Preserve optionality for future microservice/BFF needs without forcing it now
- Avoid creating a new “smart routing” layer that becomes hard to reason about

## Consequences

### Positive

- Clear edge layering: Front Door is the edge; apps are origins
- Lower operational complexity for the baseline template
- Easier debugging (fewer hops) and simpler failure modes

### Negative / trade-offs

- Front Door rules engine is less flexible than a full gateway for advanced transforms
- If/when multiple backend services emerge, routing complexity may push us toward a gateway or APIM

### Neutral / follow-ups

- Document streaming/large-upload constraints (SSE/WebSockets/file uploads) for both direct-to-app and gateway scenarios.
- Add smoke tests for host/path routing and health probes.

## Alternatives considered

- **API Management as the default edge**: strong policy/portal capabilities, but higher cost and complexity for the baseline.
- **Gateway/proxy as default**: flexible, but adds latency/ops burden and increases risk of “smart proxy” anti-patterns.
- **No Front Door**: simpler in dev, but loses WAF, global edge, and consistent custom domain strategy.

## References

- `PLAN.md`
- `infra/bicep/README.md`
- `infra/bicep/modules/frontDoor.standardPremium.bicep`

