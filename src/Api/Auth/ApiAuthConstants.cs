/*
module: src.api.auth
purpose: Define authentication scheme and policy names for the API.
exports:
  - static: ApiAuthConstants
patterns:
  - authentication
  - authorization
*/
namespace ProjectArchitecture.Api.Auth;

public static class ApiAuthConstants
{
    public const string PolicyScheme = "ApiPolicyScheme";
    public const string B2CScheme = "B2C";
    public const string EntraScheme = "Entra";
    public const string DevScheme = "DevAuth";

    public const string ProductPolicy = "ProductAccess";
    public const string AdminPolicy = "AdminAccess";
}
