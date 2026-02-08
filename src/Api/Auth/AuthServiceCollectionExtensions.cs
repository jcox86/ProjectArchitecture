/*
module: src.api.auth
purpose: Configure authentication and authorization services for the API.
exports:
  - extension: AddApiAuthentication(IServiceCollection, IConfiguration, IHostEnvironment)
patterns:
  - authentication
  - authorization
  - abac
*/
using System;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;

namespace ProjectArchitecture.Api.Auth;

public static class AuthServiceCollectionExtensions
{
    public static IServiceCollection AddApiAuthentication(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        services.Configure<AuthOptions>(configuration.GetSection(AuthOptions.SectionName));

        var authOptions = configuration.GetSection(AuthOptions.SectionName).Get<AuthOptions>() ?? new AuthOptions();

        services.AddAuthentication(options =>
            {
                options.DefaultScheme = ApiAuthConstants.PolicyScheme;
                options.DefaultChallengeScheme = ApiAuthConstants.PolicyScheme;
            })
            .AddPolicyScheme(ApiAuthConstants.PolicyScheme, "API policy scheme", policy =>
            {
                policy.ForwardDefaultSelector = context =>
                {
                    var devEnabled = authOptions.Dev.Enabled
                        && (environment.IsDevelopment() || environment.IsEnvironment("Test"));
                    if (devEnabled
                        && context.Request.Headers.TryGetValue(authOptions.Dev.HeaderName, out var headerValues)
                        && headerValues.Count > 0
                        && IsDevHeaderEnabled(headerValues[0]))
                    {
                        return ApiAuthConstants.DevScheme;
                    }

                    var path = context.Request.Path;
                    if (path.StartsWithSegments("/api/admin"))
                    {
                        return ApiAuthConstants.EntraScheme;
                    }

                    return ApiAuthConstants.B2CScheme;
                };
            })
            .AddJwtBearer(ApiAuthConstants.B2CScheme, options =>
            {
                options.Authority = authOptions.B2C.Authority;
                options.Audience = authOptions.B2C.Audience;
            })
            .AddJwtBearer(ApiAuthConstants.EntraScheme, options =>
            {
                options.Authority = authOptions.Entra.Authority;
                options.Audience = authOptions.Entra.Audience;
            })
            .AddScheme<AuthenticationSchemeOptions, DevAuthenticationHandler>(ApiAuthConstants.DevScheme, _ => { });

        services.AddAuthorization(options =>
        {
            options.AddPolicy(ApiAuthConstants.ProductPolicy, policy =>
            {
                policy.AddAuthenticationSchemes(ApiAuthConstants.B2CScheme, ApiAuthConstants.DevScheme);
                policy.RequireAuthenticatedUser();
                policy.AddRequirements(new PermissionRequirement(authOptions.Authorization.ProductPermissions));
            });
            options.AddPolicy(ApiAuthConstants.AdminPolicy, policy =>
            {
                policy.AddAuthenticationSchemes(ApiAuthConstants.EntraScheme, ApiAuthConstants.DevScheme);
                policy.RequireAuthenticatedUser();
                policy.AddRequirements(new PermissionRequirement(authOptions.Authorization.AdminPermissions));
            });
        });

        services.AddSingleton<IAuthorizationHandler, AbacAuthorizationHandler>();

        return services;
    }

    private static bool IsDevHeaderEnabled(string? value)
        => value is not null
           && (value.Equals("true", StringComparison.OrdinalIgnoreCase)
               || value.Equals("1", StringComparison.OrdinalIgnoreCase)
               || value.Equals("yes", StringComparison.OrdinalIgnoreCase));
}
