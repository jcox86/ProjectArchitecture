/*
module: src.infrastructure.auth
purpose: Cache ABAC subject attributes with Redis-backed invalidation.
exports:
  - class: CachedSubjectAttributeProvider
patterns:
  - abac
  - redis_cache
*/
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Auth;

namespace ProjectArchitecture.Infrastructure.Auth;

internal sealed class CachedSubjectAttributeProvider(
    ClaimSubjectAttributeProvider innerProvider,
    ISubjectAttributeCache cache,
    ISubjectAttributeVersionStore versionStore,
    IOptions<AbacCacheOptions> options,
    ILogger<CachedSubjectAttributeProvider> logger) : ISubjectAttributeProvider
{
    private readonly AbacCacheOptions _options = options.Value;

    public async Task<SubjectAttributes> GetAttributesAsync(SubjectAttributeRequest request, CancellationToken cancellationToken)
    {
        var subjectId = SubjectIdentifierResolver.Resolve(request.Principal);
        if (string.IsNullOrWhiteSpace(subjectId))
        {
            return await innerProvider.GetAttributesAsync(request, cancellationToken);
        }

        var tenantKey = request.TenantId?.ToString("D");
        var cacheKey = SubjectAttributeCacheKeys.Attributes(_options.KeyPrefix, subjectId, tenantKey);
        var versionKey = SubjectAttributeCacheKeys.Version(_options.KeyPrefix, subjectId, tenantKey);

        try
        {
            var currentVersion = await versionStore.GetAsync(versionKey, cancellationToken);
            var cached = await cache.GetAsync(cacheKey, cancellationToken);
            if (cached is not null && cached.Version == currentVersion)
            {
                return ToAttributes(cached.Payload);
            }

            var attributes = await innerProvider.GetAttributesAsync(request, cancellationToken);
            var payload = ToPayload(attributes);
            var entry = new SubjectAttributeCacheEntry(currentVersion, payload, DateTimeOffset.UtcNow);
            await cache.SetAsync(cacheKey, entry, _options.CacheTtl, cancellationToken);

            return attributes;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to resolve ABAC attributes for subject {SubjectId}", subjectId);
            return await innerProvider.GetAttributesAsync(request, cancellationToken);
        }
    }

    private static SubjectAttributeCachePayload ToPayload(SubjectAttributes attributes)
        => new(
            attributes.Permissions.ToArray(),
            attributes.Roles.ToArray(),
            new Dictionary<string, string>(attributes.Attributes, StringComparer.OrdinalIgnoreCase));

    private static SubjectAttributes ToAttributes(SubjectAttributeCachePayload payload)
        => new(
            new HashSet<string>(payload.Permissions, StringComparer.OrdinalIgnoreCase),
            new HashSet<string>(payload.Roles, StringComparer.OrdinalIgnoreCase),
            new Dictionary<string, string>(payload.Attributes, StringComparer.OrdinalIgnoreCase));
}
