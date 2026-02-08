/*
module: src.infrastructure.tenancy
purpose: Abstract tenant routing cache for Redis-backed or no-op implementations.
exports:
  - interface: ITenantCache
patterns:
  - caching
*/
using ProjectArchitecture.Domain.Tenancy;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal interface ITenantCache
{
    Task<TenantResolution?> GetAsync(string host, CancellationToken cancellationToken);

    Task SetAsync(string host, TenantResolution resolution, TimeSpan ttl, CancellationToken cancellationToken);
}
