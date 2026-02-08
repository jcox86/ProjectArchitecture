/*
module: src.application.tenancy
purpose: Resolve tenants by host name for request routing.
exports:
  - interface: ITenantResolutionService
patterns:
  - dependency_inversion
*/
using ProjectArchitecture.Domain.Tenancy;

namespace ProjectArchitecture.Application.Tenancy;

public interface ITenantResolutionService
{
    Task<TenantResolution?> ResolveAsync(string host, CancellationToken cancellationToken);
}
