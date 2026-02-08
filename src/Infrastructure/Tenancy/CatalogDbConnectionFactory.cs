/*
module: src.infrastructure.tenancy
purpose: Open catalog database connections for tenant routing lookups.
exports:
  - class: CatalogDbConnectionFactory
patterns:
  - data_access
*/
using Microsoft.Extensions.Logging;
using Npgsql;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal sealed class CatalogDbConnectionFactory(
    IPostgresConnectionStringFactory connectionStringFactory,
    ILogger<CatalogDbConnectionFactory> logger)
{
    public async Task<NpgsqlConnection> OpenConnectionAsync(CancellationToken cancellationToken)
    {
        try
        {
            var connection = new NpgsqlConnection(connectionStringFactory.BuildCatalogConnectionString());
            await connection.OpenAsync(cancellationToken);
            return connection;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to open catalog database connection.");
            throw;
        }
    }
}
