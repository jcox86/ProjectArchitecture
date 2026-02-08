/*
module: src.infrastructure.auth
purpose: Store ABAC subject attributes in Redis for fast authorization checks.
exports:
  - class: RedisSubjectAttributeCache
patterns:
  - abac
  - redis_cache
*/
using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace ProjectArchitecture.Infrastructure.Auth;

internal sealed class RedisSubjectAttributeCache(
    IConnectionMultiplexer multiplexer,
    ILogger<RedisSubjectAttributeCache> logger) : ISubjectAttributeCache
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private readonly IDatabase _database = multiplexer.GetDatabase();

    public async Task<SubjectAttributeCacheEntry?> GetAsync(string cacheKey, CancellationToken cancellationToken)
    {
        try
        {
            var value = await _database.StringGetAsync(cacheKey);
            if (!value.HasValue)
            {
                return null;
            }

            return JsonSerializer.Deserialize<SubjectAttributeCacheEntry>(value.ToString(), SerializerOptions);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to read ABAC cache entry {CacheKey}", cacheKey);
            return null;
        }
    }

    public async Task SetAsync(string cacheKey, SubjectAttributeCacheEntry entry, TimeSpan ttl, CancellationToken cancellationToken)
    {
        try
        {
            var payload = JsonSerializer.Serialize(entry, SerializerOptions);
            await _database.StringSetAsync(cacheKey, payload, ttl);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to write ABAC cache entry {CacheKey}", cacheKey);
        }
    }
}
