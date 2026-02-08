/*
module: src.domain.tenancy
purpose: Indicate the lookup source for a tenant resolution.
exports:
  - enum: TenantResolutionSource
patterns:
  - domain_model
*/
namespace ProjectArchitecture.Domain.Tenancy;

public enum TenantResolutionSource
{
    Cache = 1,
    Catalog = 2
}
