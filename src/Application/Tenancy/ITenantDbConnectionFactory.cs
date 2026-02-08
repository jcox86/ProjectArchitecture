/*
module: src.application.tenancy
purpose: Open tenant-aware data-plane connections with RLS configured.
exports:
  - interface: ITenantDbConnectionFactory
patterns:
  - dependency_inversion
*/
using System.Data.Common;

namespace ProjectArchitecture.Application.Tenancy;

public interface ITenantDbConnectionFactory
{
    Task<DbConnection> OpenConnectionAsync(CancellationToken cancellationToken);
}
