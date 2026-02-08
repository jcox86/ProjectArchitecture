/*
module: src.infrastructure.auth
purpose: Configure Redis-backed ABAC attribute caching behavior.
exports:
  - options: AbacCacheOptions
patterns:
  - options_pattern
  - abac
*/
using System;

namespace ProjectArchitecture.Infrastructure.Auth;

public sealed class AbacCacheOptions
{
    public const string SectionName = "Auth:AbacCache";

    public int CacheTtlMinutes { get; init; } = 5;

    public string KeyPrefix { get; init; } = "abac";

    public TimeSpan CacheTtl => TimeSpan.FromMinutes(CacheTtlMinutes);
}
