/*
module: src.domain.tenancy
purpose: Bundle resolved tenant identity with optional database routing details.
exports:
  - record: TenantResolution
patterns:
  - domain_model
*/
namespace ProjectArchitecture.Domain.Tenancy;

public sealed record TenantResolution(
    TenantInfo Tenant,
    TenantDatabaseInfo? Database,
    TenantResolutionSource Source);
