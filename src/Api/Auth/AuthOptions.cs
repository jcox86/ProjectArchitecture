/*
module: src.api.auth
purpose: Bind authentication and authorization configuration for the API.
exports:
  - options: AuthOptions
patterns:
  - options_pattern
*/
using System.Collections.Generic;

namespace ProjectArchitecture.Api.Auth;

public sealed class AuthOptions
{
    public const string SectionName = "Auth";

    public AuthorityOptions B2C { get; init; } = new();

    public AuthorityOptions Entra { get; init; } = new();

    public AuthorizationOptions Authorization { get; init; } = new();

    public DevAuthOptions Dev { get; init; } = new();

    public sealed class AuthorityOptions
    {
        public string Authority { get; init; } = string.Empty;

        public string Audience { get; init; } = string.Empty;
    }

    public sealed class AuthorizationOptions
    {
        public List<string> ProductPermissions { get; init; } = ["product.access"];

        public List<string> AdminPermissions { get; init; } = ["admin.access", "role:admin"];
    }
}
