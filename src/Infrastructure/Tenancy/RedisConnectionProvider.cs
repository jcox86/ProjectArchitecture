/*
module: src.infrastructure.tenancy
purpose: Establish a Redis connection for tenant caching and diagnostics.
exports:
  - class: RedisConnectionProvider
patterns:
  - redis_cache
*/
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal sealed class RedisConnectionProvider : IRedisConnectionProvider, IDisposable
{
    public RedisConnectionProvider(IOptions<RedisOptions> options, ILogger<RedisConnectionProvider> logger)
    {
        var redisOptions = options.Value;
        if (string.IsNullOrWhiteSpace(redisOptions.Host))
        {
            return;
        }

        try
        {
            var configurationOptions = new ConfigurationOptions
            {
                AbortOnConnectFail = false,
                Ssl = redisOptions.Ssl
            };
            configurationOptions.EndPoints.Add(redisOptions.Host, redisOptions.Port);

            if (!string.IsNullOrWhiteSpace(redisOptions.Password))
            {
                configurationOptions.Password = redisOptions.Password;
            }

            Multiplexer = ConnectionMultiplexer.Connect(configurationOptions);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to connect to Redis.");
            Multiplexer = null;
        }
    }

    public IConnectionMultiplexer? Multiplexer { get; private set; }

    public void Dispose()
    {
        Multiplexer?.Dispose();
    }
}
