/*
module: src.infrastructure.auth
purpose: Resolve stable subject identifiers from claims for caching.
exports:
  - class: SubjectIdentifierResolver
patterns:
  - abac
*/
using System.Security.Claims;

namespace ProjectArchitecture.Infrastructure.Auth;

internal static class SubjectIdentifierResolver
{
    public static string? Resolve(ClaimsPrincipal principal)
        => principal.FindFirst("sub")?.Value
           ?? principal.FindFirst("oid")?.Value
           ?? principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}
