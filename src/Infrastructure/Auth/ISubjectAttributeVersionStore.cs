/*
module: src.infrastructure.auth
purpose: Track ABAC attribute cache versions for invalidation.
exports:
  - interface: ISubjectAttributeVersionStore
patterns:
  - abac
  - redis_cache
*/
using System.Threading;
using System.Threading.Tasks;

namespace ProjectArchitecture.Infrastructure.Auth;

internal interface ISubjectAttributeVersionStore
{
    Task<long> GetAsync(string versionKey, CancellationToken cancellationToken);

    Task<long> IncrementAsync(string versionKey, CancellationToken cancellationToken);
}
