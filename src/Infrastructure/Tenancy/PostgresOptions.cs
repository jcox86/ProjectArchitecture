/*
module: src.infrastructure.tenancy
purpose: Bind Postgres connection settings required for catalog and tenant routing.
exports:
  - options: PostgresOptions
patterns:
  - configuration_binding
*/
namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class PostgresOptions
{
    public const string SectionName = "Postgres";

    public string Host { get; init; } = string.Empty;

    public int Port { get; init; } = 5432;

    public string Username { get; init; } = string.Empty;

    public string Password { get; init; } = string.Empty;

    public string CatalogDb { get; init; } = "catalog";

    public string TenantSharedDb { get; init; } = "tenant_shared";
}
