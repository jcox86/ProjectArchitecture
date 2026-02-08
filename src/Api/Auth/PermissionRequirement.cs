/*
module: src.api.auth
purpose: Require specific ABAC permissions for API policies.
exports:
  - requirement: PermissionRequirement
patterns:
  - authorization
  - abac
*/
using System.Collections.Generic;
using Microsoft.AspNetCore.Authorization;

namespace ProjectArchitecture.Api.Auth;

public sealed class PermissionRequirement(IReadOnlyCollection<string> permissions) : IAuthorizationRequirement
{
    public IReadOnlyCollection<string> Permissions { get; } = permissions;
}
