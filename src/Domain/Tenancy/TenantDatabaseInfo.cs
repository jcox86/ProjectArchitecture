/*
module: src.domain.tenancy
purpose: Capture dedicated database routing details for isolated tenants.
exports:
  - record: TenantDatabaseInfo
patterns:
  - domain_model
*/
namespace ProjectArchitecture.Domain.Tenancy;

public sealed record TenantDatabaseInfo(string DatabaseName, string? ServerName);
