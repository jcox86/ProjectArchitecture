/*
module: src.domain.tenancy
purpose: Represent resolved tenant identity and tier.
exports:
  - record: TenantInfo
patterns:
  - domain_model
*/
namespace ProjectArchitecture.Domain.Tenancy;

public sealed record TenantInfo(Guid TenantId, string TenantKey, TenantTier Tier);
