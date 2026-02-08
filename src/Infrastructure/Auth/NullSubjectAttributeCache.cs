/*
module: src.infrastructure.auth
purpose: Provide a no-op ABAC cache when Redis is unavailable.
exports:
  - class: NullSubjectAttributeCache
patterns:
  - abac
*/
using System.Threading;
using System.Threading.Tasks;

namespace ProjectArchitecture.Infrastructure.Auth;

internal sealed class NullSubjectAttributeCache : ISubjectAttributeCache
{
    public Task<SubjectAttributeCacheEntry?> GetAsync(string cacheKey, CancellationToken cancellationToken)
        => Task.FromResult<SubjectAttributeCacheEntry?>(null);

    public Task SetAsync(string cacheKey, SubjectAttributeCacheEntry entry, TimeSpan ttl, CancellationToken cancellationToken)
        => Task.CompletedTask;
}
