/*
module: src.domain.tenancy
purpose: Define tenant tier identifiers aligned with catalog lookups.
exports:
  - enum: TenantTier
patterns:
  - domain_model
notes:
  - Values must match catalog.tenant_tier seed IDs.
*/
namespace ProjectArchitecture.Domain.Tenancy;

public enum TenantTier : short
{
    Shared = 1,
    Isolated = 2
}
