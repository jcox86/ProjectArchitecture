/*
module: src.infrastructure.tenancy
purpose: Provide a safe no-op tenant cache when Redis is unavailable.
exports:
  - class: NullTenantCache
patterns:
  - caching
*/
using ProjectArchitecture.Domain.Tenancy;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal sealed class NullTenantCache : ITenantCache
{
    public Task<TenantResolution?> GetAsync(string host, CancellationToken cancellationToken)
        => Task.FromResult<TenantResolution?>(null);

    public Task SetAsync(string host, TenantResolution resolution, TimeSpan ttl, CancellationToken cancellationToken)
        => Task.CompletedTask;
}
