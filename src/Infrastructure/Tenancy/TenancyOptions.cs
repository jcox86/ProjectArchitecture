/*
module: src.infrastructure.tenancy
purpose: Configure tenant resolution behavior and caching defaults.
exports:
  - options: TenancyOptions
patterns:
  - configuration_binding
*/
namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class TenancyOptions
{
    public const string SectionName = "Tenancy";

    public int CacheTtlMinutes { get; init; } = 5;

    public string AdminHostPrefix { get; init; } = "admin";

    public string[] BypassHosts { get; init; } = new[] { "localhost", "127.0.0.1" };
}
