/*
module: src.api.auth
purpose: Authenticate local/dev requests using a trusted header and static claims.
exports:
  - handler: DevAuthenticationHandler
patterns:
  - authentication
*/
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Text.Encodings.Web;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace ProjectArchitecture.Api.Auth;

public sealed class DevAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    private readonly IOptions<AuthOptions> _options;

    public DevAuthenticationHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> schemeOptions,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IOptions<AuthOptions> options)
        : base(schemeOptions, logger, encoder)
    {
        _options = options;
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var devOptions = _options.Value.Dev;
        if (!devOptions.Enabled)
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        if (!Request.Headers.TryGetValue(devOptions.HeaderName, out var headerValues)
            || headerValues.Count == 0
            || !IsEnabledHeader(headerValues[0]))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, devOptions.SubjectId),
            new(ClaimTypes.Name, devOptions.DisplayName)
        };

        foreach (var role in devOptions.Roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        foreach (var permission in devOptions.Permissions)
        {
            claims.Add(new Claim("permissions", permission));
        }

        var identity = new ClaimsIdentity(claims, ApiAuthConstants.DevScheme);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, ApiAuthConstants.DevScheme);

        return Task.FromResult(AuthenticateResult.Success(ticket));
    }

    private static bool IsEnabledHeader(string? value)
        => value is not null
           && (value.Equals("true", StringComparison.OrdinalIgnoreCase)
               || value.Equals("1", StringComparison.OrdinalIgnoreCase)
               || value.Equals("yes", StringComparison.OrdinalIgnoreCase));
}
