/*
module: src.api.auth
purpose: Configure the development/test authentication handler.
exports:
  - options: DevAuthOptions
patterns:
  - authentication
*/
namespace ProjectArchitecture.Api.Auth;

public sealed class DevAuthOptions
{
    public bool Enabled { get; init; }

    public string HeaderName { get; init; } = "X-Dev-Auth";

    public string SubjectId { get; init; } = "dev-user";

    public string DisplayName { get; init; } = "Dev User";

    public string[] Roles { get; init; } = ["admin"];

    public string[] Permissions { get; init; } = ["admin.access", "product.access"];
}
