/*
module: src.infrastructure.tenancy
purpose: Build Postgres connection strings for catalog and tenant databases.
exports:
  - interface: IPostgresConnectionStringFactory
patterns:
  - configuration_binding
*/
namespace ProjectArchitecture.Infrastructure.Tenancy;

public interface IPostgresConnectionStringFactory
{
    string BuildCatalogConnectionString();

    string BuildSharedTenantConnectionString();

    string BuildTenantConnectionString(string databaseName, string? serverName);
}
