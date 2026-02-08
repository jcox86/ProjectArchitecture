/*
module: src.infrastructure.tenancy
purpose: Store the current tenant resolution in an async-local scope.
exports:
  - class: TenantContextAccessor
patterns:
  - ambient_context
*/
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Domain.Tenancy;

namespace ProjectArchitecture.Infrastructure.Tenancy;

public sealed class TenantContextAccessor : ITenantContextAccessor
{
    private static readonly AsyncLocal<TenantResolution?> CurrentContext = new();

    public TenantResolution? Current
    {
        get => CurrentContext.Value;
        set => CurrentContext.Value = value;
    }
}
