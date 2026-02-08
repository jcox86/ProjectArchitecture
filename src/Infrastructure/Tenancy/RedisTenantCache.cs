/*
module: src.infrastructure.tenancy
purpose: Cache tenant routing resolutions in Redis for fast lookups.
exports:
  - class: RedisTenantCache
patterns:
  - redis_cache
*/
using System.Text.Json;
using Microsoft.Extensions.Logging;
using ProjectArchitecture.Domain.Tenancy;
using StackExchange.Redis;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal sealed class RedisTenantCache(IConnectionMultiplexer multiplexer, ILogger<RedisTenantCache> logger) : ITenantCache
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private readonly IDatabase _database = multiplexer.GetDatabase();

    public async Task<TenantResolution?> GetAsync(string host, CancellationToken cancellationToken)
    {
        try
        {
            var value = await _database.StringGetAsync(CacheKey(host));
            if (!value.HasValue)
            {
                return null;
            }

            return JsonSerializer.Deserialize<TenantResolution>(value.ToString(), SerializerOptions);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to read tenant cache for host {Host}", host);
            return null;
        }
    }

    public async Task SetAsync(string host, TenantResolution resolution, TimeSpan ttl, CancellationToken cancellationToken)
    {
        try
        {
            var payload = JsonSerializer.Serialize(resolution, SerializerOptions);
            await _database.StringSetAsync(CacheKey(host), payload, ttl);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to write tenant cache for host {Host}", host);
        }
    }

    private static RedisKey CacheKey(string host) => $"tenancy:host:{host}";

}
