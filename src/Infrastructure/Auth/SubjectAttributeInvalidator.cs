/*
module: src.infrastructure.auth
purpose: Invalidate ABAC attribute cache entries using Redis versions.
exports:
  - class: SubjectAttributeInvalidator
patterns:
  - abac
  - redis_cache
*/
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Auth;

namespace ProjectArchitecture.Infrastructure.Auth;

internal sealed class SubjectAttributeInvalidator(
    ISubjectAttributeVersionStore versionStore,
    IOptions<AbacCacheOptions> options,
    ILogger<SubjectAttributeInvalidator> logger) : ISubjectAttributeInvalidator
{
    private readonly AbacCacheOptions _options = options.Value;

    public async Task InvalidateAsync(SubjectAttributeInvalidation invalidation, CancellationToken cancellationToken)
    {
        try
        {
            var tenantKey = invalidation.TenantId?.ToString("D");
            var versionKey = SubjectAttributeCacheKeys.Version(_options.KeyPrefix, invalidation.SubjectId, tenantKey);
            await versionStore.IncrementAsync(versionKey, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to invalidate ABAC cache for subject {SubjectId}", invalidation.SubjectId);
        }
    }
}
