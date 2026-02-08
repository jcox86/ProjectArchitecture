/*
module: src.api.auth
purpose: Enforce ABAC permissions using cached subject attributes.
exports:
  - handler: AbacAuthorizationHandler
patterns:
  - authorization
  - abac
*/
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using ProjectArchitecture.Application.Auth;
using ProjectArchitecture.Application.Tenancy;

namespace ProjectArchitecture.Api.Auth;

public sealed class AbacAuthorizationHandler(
    ISubjectAttributeProvider attributeProvider,
    ITenantContextAccessor tenantContextAccessor,
    ILogger<AbacAuthorizationHandler> logger) : AuthorizationHandler<PermissionRequirement>
{
    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PermissionRequirement requirement)
    {
        if (context.User.Identity?.IsAuthenticated != true)
        {
            return;
        }

        var tenantId = tenantContextAccessor.Current?.Tenant.TenantId;
        var request = new SubjectAttributeRequest(context.User, tenantId, context.User.Identity?.AuthenticationType);

        try
        {
            var attributes = await attributeProvider.GetAttributesAsync(request, CancellationToken.None);
            if (requirement.Permissions.Count == 0)
            {
                context.Succeed(requirement);
                return;
            }

            foreach (var permission in requirement.Permissions)
            {
                if (permission.StartsWith("role:", StringComparison.OrdinalIgnoreCase))
                {
                    var role = permission["role:".Length..];
                    if (attributes.HasRole(role))
                    {
                        context.Succeed(requirement);
                        return;
                    }
                }
                else if (attributes.HasPermission(permission))
                {
                    context.Succeed(requirement);
                    return;
                }
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to evaluate ABAC permissions for {Subject}", context.User.Identity?.Name);
        }
    }
}
