/*
module: src.application.auth
purpose: Represent cached attribute-based access control data for a subject.
exports:
  - record: SubjectAttributes
patterns:
  - abac
*/
using System;
using System.Collections.Generic;

namespace ProjectArchitecture.Application.Auth;

public sealed record SubjectAttributes(
    HashSet<string> Permissions,
    HashSet<string> Roles,
    Dictionary<string, string> Attributes)
{
    public static SubjectAttributes Empty { get; } = new(
        new HashSet<string>(StringComparer.OrdinalIgnoreCase),
        new HashSet<string>(StringComparer.OrdinalIgnoreCase),
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase));

    public bool HasPermission(string permission) => Permissions.Contains(permission);

    public bool HasRole(string role) => Roles.Contains(role);

    public string? TryGetAttribute(string key)
        => Attributes.TryGetValue(key, out var value) ? value : null;
}
