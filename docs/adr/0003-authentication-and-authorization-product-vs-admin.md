<!--
module: docs.adr.auth
purpose: Record the decision to split product and admin authentication schemes and to use ABAC authorization with cached attributes.
exports:
  - decision: product_auth_b2c_external_id
  - decision: admin_auth_entra_id
  - decision: abac_authorization_with_redis_cache
patterns:
  - adr
  - dual_auth_schemes
  - abac
-->

# ADR 0003: Authentication and authorization (product vs admin)

- **Status**: Accepted
- **Date**: 2026-02-04
- **Deciders**: Template maintainers

## Context

The template supports two distinct user populations with different expectations:

- **Product users**: end users of the SaaS product (self-serve sign-up, external identities)
- **Admin staff**: internal operators (enterprise identity, stronger controls)

We must avoid “auth confusion” where a token intended for one audience is accepted in the other context. We also need flexible authorization beyond coarse roles (tenant-level and attribute-based policies).

## Decision

1. **Authentication is split by audience**
   - **Product** authentication uses **Azure AD B2C / External ID**.
   - **Admin** authentication uses **Microsoft Entra ID**.
   - API routes are configured with explicit auth schemes/policies to prevent token cross-acceptance.

2. **Authorization uses ABAC**
   - Authorization decisions are made using **Attribute-Based Access Control (ABAC)** policies.
   - User/tenant attributes used for decisions are cached in **Redis** to reduce repeated lookups and to centralize evaluation inputs.

3. **Developer/test convenience**
   - Provide a dev/test authentication handler (or equivalent) to enable local/integration testing without external dependencies, while ensuring it cannot be enabled in production.

## Decision drivers

- Separate trust boundaries for product vs admin access
- Clear route-level enforcement and least surprise
- ABAC needed for tenant-aware and context-aware permissions
- Performance and reliability: cache attributes and avoid per-request expensive lookups

## Consequences

### Positive

- Reduced risk of accepting the wrong tokens on the wrong endpoints
- Cleaner operational story: admin access can use enterprise controls (Conditional Access, MFA, etc.)
- ABAC supports richer policies without exploding role counts

### Negative / trade-offs

- More configuration and testing: two auth schemes, two sets of policies, and careful endpoint partitioning
- Requires claim normalization and consistent identity representation across schemes
- Redis cache introduces a dependency; cache invalidation and TTL need to be designed

### Neutral / follow-ups

- Add integration tests that prove:
  - Admin tokens do not grant product endpoints (and vice versa)
  - ABAC policy decisions are deterministic given a set of attributes
- Define canonical claim/identity model (subject, tenant membership, admin roles) and document it in `docs/security/`.

## Alternatives considered

- **Single identity provider for all users**: simpler, but does not match separate operational/security expectations and increases risk of boundary mistakes.
- **Role-based authorization only**: too rigid; ABAC better models tenant-aware and contextual permissions.
- **No caching**: simpler but can be too expensive or flaky if attribute sources are external.

## References

- `PLAN.md`
- `docs/security/README.md`

