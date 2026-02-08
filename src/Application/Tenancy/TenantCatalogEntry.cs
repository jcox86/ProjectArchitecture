/*
module: src.application.tenancy
purpose: Describe tenant routing information required for background processing.
exports:
  - record: TenantCatalogEntry
patterns:
  - tenant_routing
*/
using ProjectArchitecture.Domain.Tenancy;

namespace ProjectArchitecture.Application.Tenancy;

public sealed record TenantCatalogEntry(
    Guid TenantId,
    TenantTier Tier,
    string? DatabaseName,
    string? ServerName);
