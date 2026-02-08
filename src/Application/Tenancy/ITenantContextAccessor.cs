/*
module: src.application.tenancy
purpose: Provide ambient access to the current tenant resolution.
exports:
  - interface: ITenantContextAccessor
patterns:
  - dependency_inversion
*/
using ProjectArchitecture.Domain.Tenancy;

namespace ProjectArchitecture.Application.Tenancy;

public interface ITenantContextAccessor
{
    TenantResolution? Current { get; set; }
}
