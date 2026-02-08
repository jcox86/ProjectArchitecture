/*
module: src.infrastructure.tenancy
purpose: Expose Redis server version for diagnostics.
exports:
  - interface: IRedisVersionProvider
patterns:
  - diagnostics
*/
namespace ProjectArchitecture.Infrastructure.Tenancy;

public interface IRedisVersionProvider
{
    Task<string?> GetVersionAsync(CancellationToken cancellationToken);
}
