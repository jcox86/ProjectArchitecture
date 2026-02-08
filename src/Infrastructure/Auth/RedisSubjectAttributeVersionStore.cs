/*
module: src.infrastructure.auth
purpose: Track ABAC attribute cache versions in Redis for invalidation.
exports:
  - class: RedisSubjectAttributeVersionStore
patterns:
  - abac
  - redis_cache
*/
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace ProjectArchitecture.Infrastructure.Auth;

internal sealed class RedisSubjectAttributeVersionStore(
    IConnectionMultiplexer multiplexer,
    ILogger<RedisSubjectAttributeVersionStore> logger) : ISubjectAttributeVersionStore
{
    private readonly IDatabase _database = multiplexer.GetDatabase();

    public async Task<long> GetAsync(string versionKey, CancellationToken cancellationToken)
    {
        try
        {
            var value = await _database.StringGetAsync(versionKey);
            return value.HasValue && long.TryParse(value.ToString(), out var version)
                ? version
                : 0;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to read ABAC version for {VersionKey}", versionKey);
            return 0;
        }
    }

    public async Task<long> IncrementAsync(string versionKey, CancellationToken cancellationToken)
    {
        try
        {
            return await _database.StringIncrementAsync(versionKey);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to increment ABAC version for {VersionKey}", versionKey);
            return 0;
        }
    }
}
