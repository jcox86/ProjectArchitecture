/*
module: src.api.middleware
purpose: Capture correlation identifiers and enrich logs/activities with tenant and user context.
exports:
  - middleware: CorrelationContextMiddleware
patterns:
  - correlation_id
  - logging_scope
*/
using System.Diagnostics;
using System.Security.Claims;
using ProjectArchitecture.Application.Tenancy;

namespace ProjectArchitecture.Api.Middleware;

public sealed class CorrelationContextMiddleware(
    RequestDelegate next,
    ITenantContextAccessor tenantContextAccessor,
    ILogger<CorrelationContextMiddleware> logger)
{
    private const string CorrelationHeaderName = "X-Correlation-ID";
    private const string CorrelationItemKey = "CorrelationId";

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = GetOrCreateCorrelationId(context);
        context.Items[CorrelationItemKey] = correlationId;

        context.Response.OnStarting(() =>
        {
            context.Response.Headers[CorrelationHeaderName] = correlationId;
            return Task.CompletedTask;
        });

        var tenantId = tenantContextAccessor.Current?.Tenant?.TenantId;
        var userId = ResolveUserId(context.User);

        var activity = Activity.Current;
        if (activity is not null)
        {
            activity.SetTag("correlation.id", correlationId);
            if (tenantId is not null)
            {
                activity.SetTag("tenant.id", tenantId);
                activity.AddBaggage("tenant.id", tenantId.ToString());
            }

            if (!string.IsNullOrWhiteSpace(userId))
            {
                activity.SetTag("user.id", userId);
                activity.AddBaggage("user.id", userId);
            }

            activity.AddBaggage("correlation.id", correlationId);
        }

        using var scope = logger.BeginScope(new Dictionary<string, object?>
        {
            ["correlationId"] = correlationId,
            ["tenantId"] = tenantId?.ToString(),
            ["userId"] = userId,
            ["traceId"] = activity?.TraceId.ToString()
        });

        await next(context);
    }

    private static string GetOrCreateCorrelationId(HttpContext context)
    {
        if (context.Request.Headers.TryGetValue(CorrelationHeaderName, out var values))
        {
            var headerValue = values.ToString().Trim();
            if (!string.IsNullOrWhiteSpace(headerValue))
            {
                context.TraceIdentifier = headerValue;
                return headerValue;
            }
        }

        var correlationId = Guid.NewGuid().ToString("N");
        context.TraceIdentifier = correlationId;
        return correlationId;
    }

    private static string? ResolveUserId(ClaimsPrincipal user)
    {
        if (user.Identity?.IsAuthenticated != true)
        {
            return null;
        }

        return user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub")
            ?? user.FindFirstValue("oid")
            ?? user.Identity?.Name;
    }
}
