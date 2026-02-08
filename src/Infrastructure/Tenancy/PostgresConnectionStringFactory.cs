/*
module: src.infrastructure.tenancy
purpose: Construct Postgres connection strings based on configured defaults.
exports:
  - class: PostgresConnectionStringFactory
patterns:
  - configuration_binding
*/
using Microsoft.Extensions.Options;
using Npgsql;

namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class PostgresConnectionStringFactory(IOptions<PostgresOptions> options) : IPostgresConnectionStringFactory
{
    private readonly PostgresOptions _options = options.Value;

    public string BuildCatalogConnectionString()
        => BuildTenantConnectionString(_options.CatalogDb, null);

    public string BuildSharedTenantConnectionString()
        => BuildTenantConnectionString(_options.TenantSharedDb, null);

    public string BuildTenantConnectionString(string databaseName, string? serverName)
    {
        var builder = new NpgsqlConnectionStringBuilder
        {
            Host = string.IsNullOrWhiteSpace(serverName) ? _options.Host : serverName,
            Port = _options.Port,
            Username = _options.Username,
            Password = _options.Password,
            Database = databaseName,
            ApplicationName = "ProjectArchitecture",
            Pooling = true
        };

        return builder.ConnectionString;
    }
}
