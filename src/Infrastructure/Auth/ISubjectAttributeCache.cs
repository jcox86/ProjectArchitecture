/*
module: src.infrastructure.auth
purpose: Provide cache storage for ABAC subject attributes.
exports:
  - interface: ISubjectAttributeCache
patterns:
  - abac
  - redis_cache
*/
using System;
using System.Threading;
using System.Threading.Tasks;

namespace ProjectArchitecture.Infrastructure.Auth;

internal interface ISubjectAttributeCache
{
    Task<SubjectAttributeCacheEntry?> GetAsync(string cacheKey, CancellationToken cancellationToken);

    Task SetAsync(string cacheKey, SubjectAttributeCacheEntry entry, TimeSpan ttl, CancellationToken cancellationToken);
}
