/*
module: src.application.tenancy
purpose: Read active tenant routing data from the catalog for background work.
exports:
  - interface: ITenantCatalogReader
patterns:
  - catalog_queries
*/
namespace ProjectArchitecture.Application.Tenancy;

public interface ITenantCatalogReader
{
    Task<IReadOnlyList<TenantCatalogEntry>> GetActiveTenantsAsync(CancellationToken cancellationToken);
}
