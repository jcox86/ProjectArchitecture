/*
module: src.infrastructure.tenancy
purpose: Read Redis server version from the connected instance.
exports:
  - class: RedisVersionProvider
patterns:
  - diagnostics
  - redis_cache
*/
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class RedisVersionProvider(
    IConnectionMultiplexer multiplexer,
    ILogger<RedisVersionProvider> logger) : IRedisVersionProvider
{
    public async Task<string?> GetVersionAsync(CancellationToken cancellationToken)
    {
        try
        {
            var endpoints = multiplexer.GetEndPoints();
            if (endpoints.Length == 0)
            {
                return null;
            }

            var server = multiplexer.GetServer(endpoints[0]);
            var sections = await server.InfoAsync("server");
            foreach (var section in sections)
            {
                foreach (var pair in section)
                {
                    if (pair.Key.Equals("redis_version", StringComparison.OrdinalIgnoreCase))
                    {
                        return pair.Value;
                    }
                }
            }

            return null;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to read Redis server version.");
            return null;
        }
    }
}
