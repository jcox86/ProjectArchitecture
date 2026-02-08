/*
module: src.infrastructure.tenancy
purpose: Open tenant-aware data-plane connections with RLS session settings applied.
exports:
  - class: TenantDbConnectionFactory
patterns:
  - data_access
  - rls
*/
using System.Data.Common;
using Dapper;
using Microsoft.Extensions.Logging;
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Domain.Tenancy;
using Npgsql;

namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class TenantDbConnectionFactory(
    ITenantContextAccessor tenantContextAccessor,
    IPostgresConnectionStringFactory connectionStringFactory,
    ILogger<TenantDbConnectionFactory> logger) : ITenantDbConnectionFactory
{
    public async Task<DbConnection> OpenConnectionAsync(CancellationToken cancellationToken)
    {
        try
        {
            var resolution = tenantContextAccessor.Current;
            if (resolution is null)
            {
                throw new InvalidOperationException("Tenant context has not been resolved.");
            }

            var connectionString = BuildTenantConnectionString(resolution);
            var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync(cancellationToken);

            var setTenantCommand = new CommandDefinition(
                "select set_config('app.tenant_id', @tenantId, false);",
                new { tenantId = resolution.Tenant.TenantId.ToString() },
                cancellationToken: cancellationToken);
            await connection.ExecuteAsync(setTenantCommand);

            return connection;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to open tenant database connection.");
            throw;
        }
    }

    private string BuildTenantConnectionString(TenantResolution resolution)
    {
        return resolution.Tenant.Tier switch
        {
            TenantTier.Shared => connectionStringFactory.BuildSharedTenantConnectionString(),
            TenantTier.Isolated => BuildIsolatedConnectionString(resolution),
            _ => throw new InvalidOperationException($"Unsupported tenant tier {resolution.Tenant.Tier}.")
        };
    }

    private string BuildIsolatedConnectionString(TenantResolution resolution)
    {
        if (resolution.Database is null)
        {
            throw new InvalidOperationException($"Tenant {resolution.Tenant.TenantId} requires a database mapping.");
        }

        return connectionStringFactory.BuildTenantConnectionString(
            resolution.Database.DatabaseName,
            resolution.Database.ServerName);
    }
}
