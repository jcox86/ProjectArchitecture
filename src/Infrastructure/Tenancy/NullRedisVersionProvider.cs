/*
module: src.infrastructure.tenancy
purpose: No-op Redis version provider when Redis is unavailable.
exports:
  - class: NullRedisVersionProvider
patterns:
  - diagnostics
*/
namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class NullRedisVersionProvider : IRedisVersionProvider
{
    public Task<string?> GetVersionAsync(CancellationToken cancellationToken)
        => Task.FromResult<string?>(null);
}
