/*
module: src.api.tenancy
purpose: Resolve tenant context from the request host and enforce routing.
exports:
  - middleware: TenantResolutionMiddleware
patterns:
  - minimal_api
  - tenant_resolution
*/
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Infrastructure.Tenancy;

namespace ProjectArchitecture.Api.Middleware;

public sealed class TenantResolutionMiddleware(
    RequestDelegate next,
    ITenantResolutionService tenantResolutionService,
    ITenantContextAccessor tenantContextAccessor,
    IOptions<TenancyOptions> options,
    ILogger<TenantResolutionMiddleware> logger)
{
    private static readonly PathString[] BypassPaths = new[]
    {
        new PathString("/health"),
        new PathString("/alive")
    };
    private readonly TenancyOptions _options = options.Value;

    public async Task InvokeAsync(HttpContext context)
    {
        if (ShouldBypass(context))
        {
            await next(context);
            return;
        }

        var host = context.Request.Host.Host;
        if (string.IsNullOrWhiteSpace(host))
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsync("Missing host.");
            return;
        }

        try
        {
            var resolution = await tenantResolutionService.ResolveAsync(host, context.RequestAborted);
            if (resolution is null)
            {
                context.Response.StatusCode = StatusCodes.Status404NotFound;
                await context.Response.WriteAsync("Tenant not found.");
                return;
            }

            tenantContextAccessor.Current = resolution;
            try
            {
                await next(context);
            }
            finally
            {
                tenantContextAccessor.Current = null;
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Tenant resolution failed for host {Host}", host);
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsync("Tenant resolution failed.");
        }
    }

    private bool ShouldBypass(HttpContext context)
    {
        var host = context.Request.Host.Host;
        if (!string.IsNullOrWhiteSpace(host))
        {
            foreach (var bypassHost in _options.BypassHosts)
            {
                if (host.Equals(bypassHost, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            if (!string.IsNullOrWhiteSpace(_options.AdminHostPrefix))
            {
                var adminPrefix = $"{_options.AdminHostPrefix}.";
                if (host.StartsWith(adminPrefix, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }
        }

        foreach (var path in BypassPaths)
        {
            if (context.Request.Path.StartsWithSegments(path, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }
}
