/*
module: src.infrastructure.tenancy
purpose: Load active tenant routing data for background processing.
exports:
  - class: TenantCatalogReader
patterns:
  - catalog_queries
  - dapper_queries
*/
using Dapper;
using Microsoft.Extensions.Logging;
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Domain.Tenancy;
using ProjectArchitecture.Infrastructure.DataAccess;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal sealed class TenantCatalogReader(
    CatalogDbConnectionFactory catalogDbConnectionFactory,
    ILogger<TenantCatalogReader> logger) : ITenantCatalogReader
{
    public async Task<IReadOnlyList<TenantCatalogEntry>> GetActiveTenantsAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            select t.tenant_id as TenantId,
                   t.tenant_tier_id as TenantTierId,
                   d.database_name as DatabaseName,
                   d.server_name as ServerName
            from catalog.tenant t
            join catalog.tenant_status s
              on s.tenant_status_id = t.tenant_status_id
             and s.status_key = 'active'
            left join catalog.tenant_database d
              on d.tenant_id = t.tenant_id
            left join catalog.tenant_database_status ds
              on ds.tenant_database_status_id = d.tenant_database_status_id
             and ds.status_key = 'active';
            """;

        try
        {
            await using var connection = await catalogDbConnectionFactory.OpenConnectionAsync(cancellationToken);
            var command = new CommandDefinition(sql, cancellationToken: cancellationToken);
            var records = (await connection.QueryAsync<TenantCatalogRecord>(command)).ToList();

            var tenants = new List<TenantCatalogEntry>(records.Count);
            foreach (var record in records)
            {
                if (!Enum.IsDefined(typeof(TenantTier), record.TenantTierId))
                {
                    logger.LogWarning("Unknown tenant tier {TierId} for tenant {TenantId}.", record.TenantTierId, record.TenantId);
                    continue;
                }

                tenants.Add(new TenantCatalogEntry(
                    record.TenantId,
                    (TenantTier)record.TenantTierId,
                    record.DatabaseName,
                    record.ServerName));
            }

            return tenants;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to load active tenants from catalog.");
            throw;
        }
    }

    private sealed record TenantCatalogRecord(Guid TenantId, short TenantTierId, string? DatabaseName, string? ServerName);
}
