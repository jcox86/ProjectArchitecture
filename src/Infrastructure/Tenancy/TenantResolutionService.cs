/*
module: src.infrastructure.tenancy
purpose: Resolve tenants by host using Redis cache and catalog database fallback.
exports:
  - class: TenantResolutionService
patterns:
  - redis_cache
  - dapper_queries
  - catalog_fallback
*/
using Dapper;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Domain.Tenancy;
using ProjectArchitecture.Infrastructure.DataAccess;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal sealed class TenantResolutionService(
    CatalogDbConnectionFactory catalogDbConnectionFactory,
    StoredFunctionExecutor storedFunctionExecutor,
    ITenantCache tenantCache,
    IOptions<TenancyOptions> options,
    ILogger<TenantResolutionService> logger) : ITenantResolutionService
{
    private readonly TenancyOptions _options = options.Value;

    public async Task<TenantResolution?> ResolveAsync(string host, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(host))
        {
            return null;
        }

        var normalizedHost = host.Trim().ToLowerInvariant();

        try
        {
            var cached = await tenantCache.GetAsync(normalizedHost, cancellationToken);
            if (cached is not null)
            {
                return cached with { Source = TenantResolutionSource.Cache };
            }

            var resolution = await GetFromCatalogAsync(normalizedHost, cancellationToken);
            if (resolution is null)
            {
                return null;
            }

            var ttl = TimeSpan.FromMinutes(Math.Max(1, _options.CacheTtlMinutes));
            await tenantCache.SetAsync(normalizedHost, resolution, ttl, cancellationToken);

            return resolution;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to resolve tenant for host {Host}", normalizedHost);
            throw;
        }
    }

    private async Task<TenantResolution?> GetFromCatalogAsync(string host, CancellationToken cancellationToken)
    {
        const string databaseSql = """
            select d.database_name as DatabaseName,
                   d.server_name as ServerName
            from catalog.tenant_database d
            join catalog.tenant_database_status s
              on s.tenant_database_status_id = d.tenant_database_status_id
            where d.tenant_id = @tenantId
              and s.status_key = 'active';
            """;

        try
        {
            await using var connection = await catalogDbConnectionFactory.OpenConnectionAsync(cancellationToken);
            var tenantRecord = await storedFunctionExecutor.QuerySingleOrDefaultAsync<TenantRecord>(
                connection,
                "catalog.resolve_tenant_by_host",
                StoredFunctionParameters.From(new { host }),
                cancellationToken);
            if (tenantRecord is null)
            {
                return null;
            }

            if (!Enum.IsDefined(typeof(TenantTier), tenantRecord.TenantTierId))
            {
                logger.LogWarning("Unknown tenant tier {TierId} for host {Host}", tenantRecord.TenantTierId, host);
                return null;
            }

            var tenant = new TenantInfo(tenantRecord.TenantId, tenantRecord.TenantKey, (TenantTier)tenantRecord.TenantTierId);
            TenantDatabaseInfo? database = null;

            if (tenant.Tier == TenantTier.Isolated)
            {
                var dbCommand = new CommandDefinition(databaseSql, new { tenantId = tenant.TenantId }, cancellationToken: cancellationToken);
                var dbRecord = await connection.QuerySingleOrDefaultAsync<TenantDatabaseRecord>(dbCommand);
                if (dbRecord is null)
                {
                    logger.LogWarning("Isolated tenant {TenantId} has no active database mapping.", tenant.TenantId);
                    return null;
                }

                database = new TenantDatabaseInfo(dbRecord.DatabaseName, dbRecord.ServerName);
            }

            return new TenantResolution(tenant, database, TenantResolutionSource.Catalog);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Catalog lookup failed for host {Host}", host);
            throw;
        }
    }

    private sealed record TenantRecord(Guid TenantId, string TenantKey, short TenantTierId);

    private sealed record TenantDatabaseRecord(string DatabaseName, string? ServerName);
}
