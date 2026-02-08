/*
module: src.infrastructure.tenancy
purpose: Bind Redis connection settings for tenant routing cache.
exports:
  - options: RedisOptions
patterns:
  - configuration_binding
*/
namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class RedisOptions
{
    public const string SectionName = "Redis";

    public string Host { get; init; } = string.Empty;

    public int Port { get; init; } = 6380;

    public string Password { get; init; } = string.Empty;

    public bool Ssl { get; init; } = true;
}
