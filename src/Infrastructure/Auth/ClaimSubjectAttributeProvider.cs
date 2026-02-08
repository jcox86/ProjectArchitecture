/*
module: src.infrastructure.auth
purpose: Build ABAC subject attributes from JWT claims.
exports:
  - class: ClaimSubjectAttributeProvider
patterns:
  - abac
*/
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using ProjectArchitecture.Application.Auth;

namespace ProjectArchitecture.Infrastructure.Auth;

public sealed class ClaimSubjectAttributeProvider : ISubjectAttributeProvider
{
    public Task<SubjectAttributes> GetAttributesAsync(SubjectAttributeRequest request, CancellationToken cancellationToken)
    {
        var permissions = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var roles = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        foreach (var claim in request.Principal.Claims)
        {
            switch (claim.Type)
            {
                case "scp":
                case "scope":
                    AddDelimitedValues(permissions, claim.Value, ' ');
                    break;
                case "permissions":
                    AddDelimitedValues(permissions, claim.Value, ' ');
                    break;
                case ClaimTypes.Role:
                case "roles":
                    AddDelimitedValues(roles, claim.Value, ' ');
                    break;
                default:
                    if (!attributes.ContainsKey(claim.Type))
                    {
                        attributes[claim.Type] = claim.Value;
                    }
                    break;
            }
        }

        if (request.TenantId is not null)
        {
            attributes["tenant_id"] = request.TenantId.Value.ToString("D");
        }

        if (!string.IsNullOrWhiteSpace(request.Scheme))
        {
            attributes["auth_scheme"] = request.Scheme!;
        }

        return Task.FromResult(new SubjectAttributes(permissions, roles, attributes));
    }

    private static void AddDelimitedValues(HashSet<string> target, string value, char delimiter)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return;
        }

        foreach (var entry in value.Split(delimiter, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            target.Add(entry);
        }
    }
}
