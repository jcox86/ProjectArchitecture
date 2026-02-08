/*
module: src.api.endpoints
purpose: Register API endpoint groups for admin and tenant routes.
exports:
  - extension: RegistrationEndpoints.MapEndpoints(WebApplication)
patterns:
  - minimal_api
*/
using System;
using System.Security.Claims;
using Dapper;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;
using ProjectArchitecture.Api.Auth;
using ProjectArchitecture.Application.Auth;
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Infrastructure.DataAccess;
using ProjectArchitecture.Infrastructure.Tenancy;

namespace ProjectArchitecture.Api.Endpoints;

public static class RegistrationEndpoints
{
    public static WebApplication MapEndpoints(this WebApplication app)
    {
        app.MapGet("/api", () => "Check out the API at /admin or /product");

        var api = app.MapGroup("api");

        api.MapAdminEndpoints();
        api.MapTenantEndpoints();

        return app;
    }

    public static RouteGroupBuilder MapAdminEndpoints(this RouteGroupBuilder api)
    {
        var adminGroup = api.MapGroup("admin");
        adminGroup.RequireAuthorization(ApiAuthConstants.AdminPolicy);

        adminGroup.MapPost("/auth/abac/invalidate", async (
            SubjectAttributeInvalidationRequest request,
            ISubjectAttributeInvalidator invalidator,
            CancellationToken cancellationToken) =>
        {
            await invalidator.InvalidateAsync(
                new SubjectAttributeInvalidation(request.SubjectId, request.TenantId),
                cancellationToken);

            return Results.Ok(new { request.SubjectId, request.TenantId });
        })
        .WithName("InvalidateAbacCache")
        .WithTags("Admin")
        .AddEndpointFilter(async (context, next) =>
        {
            var environment = context.HttpContext.RequestServices.GetRequiredService<IHostEnvironment>();
            if (environment.IsDevelopment() || environment.IsEnvironment("Test"))
            {
                return await next(context);
            }

            return Results.NotFound();
        });

        adminGroup.MapPost("/telemetry/logs", (
            UiLogBatch batch,
            HttpContext httpContext,
            ILogger<Program> logger) =>
        {
            if (batch.Logs is null || batch.Logs.Count == 0)
            {
                return Results.BadRequest("Missing logs.");
            }

            if (batch.Logs.Count > 50)
            {
                return Results.BadRequest("Too many logs in a single request.");
            }

            var subjectId = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? httpContext.User.FindFirstValue("oid")
                ?? httpContext.User.FindFirstValue("sub");

            foreach (var log in batch.Logs)
            {
                var level = log.Level?.ToLowerInvariant() switch
                {
                    "debug" => LogLevel.Debug,
                    "info" => LogLevel.Information,
                    "warn" => LogLevel.Warning,
                    "error" => LogLevel.Error,
                    _ => LogLevel.Information
                };

                var message = string.IsNullOrWhiteSpace(log.Message)
                    ? "UI log message missing."
                    : log.Message.Length > 512
                        ? log.Message[..512]
                        : log.Message;

                using var scope = logger.BeginScope(new Dictionary<string, object?>
                {
                    ["ui.correlationId"] = log.CorrelationId,
                    ["ui.userId"] = log.UserId,
                    ["ui.tenantId"] = log.TenantId,
                    ["ui.route"] = log.Route,
                    ["ui.component"] = log.Component,
                    ["ui.timestamp"] = log.Timestamp,
                    ["ui.context"] = log.Context,
                    ["ui.subjectId"] = subjectId
                });

                if (log.Error is not null)
                {
                    logger.Log(level, "UI log: {Message}. Error: {ErrorName} {ErrorMessage}",
                        message,
                        log.Error.Name,
                        log.Error.Message);
                }
                else
                {
                    logger.Log(level, "UI log: {Message}", message);
                }
            }

            return Results.Accepted();
        })
        .WithName("AdminUiLogs")
        .WithTags("Admin");

        return adminGroup;
    }

    public static RouteGroupBuilder MapTenantEndpoints(this RouteGroupBuilder api)
    {
        var productGroup = api.MapGroup("tenant");
        productGroup.RequireAuthorization(ApiAuthConstants.ProductPolicy);
        productGroup.MapGet("/tenancy/ping", async (
            ITenantDbConnectionFactory connectionFactory,
            ITenantContextAccessor tenantContextAccessor,
            IRedisVersionProvider redisVersionProvider,
            StoredFunctionExecutor storedFunctionExecutor,
            ILogger<Program> logger,
            CancellationToken cancellationToken) =>
        {
            try
            {
                await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
                var dbNameCommand = new CommandDefinition(
                    "select current_database();",
                    cancellationToken: cancellationToken);
                var dbVersionCommand = new CommandDefinition(
                    "show server_version;",
                    cancellationToken: cancellationToken);

                var tenantId = await storedFunctionExecutor.QueryScalarAsync<Guid?>(
                    connection,
                    "core.current_tenant_id",
                    StoredFunctionParameters.None,
                    cancellationToken);
                var databaseName = await connection.QuerySingleAsync<string>(dbNameCommand);
                var databaseVersion = await connection.QuerySingleAsync<string>(dbVersionCommand);
                var redisVersion = await redisVersionProvider.GetVersionAsync(cancellationToken);

                var tenant = tenantContextAccessor.Current;
                var tier = tenant?.Tenant.Tier.ToString();
                var tenantKey = tenant?.Tenant.TenantKey;
                var resolutionSource = tenant?.Source.ToString();

                return Results.Ok(new
                {
                    tenantId,
                    tenantKey,
                    tenantTier = tier,
                    resolutionSource,
                    databaseName,
                    databaseVersion,
                    redisVersion
                });
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Tenant routing ping failed.");
                return Results.Problem("Unable to verify tenant routing.");
            }
        });
        return productGroup;
    }

    private sealed record SubjectAttributeInvalidationRequest(string SubjectId, Guid? TenantId);

    private sealed record UiLogBatch(IReadOnlyList<UiLogEvent> Logs);

    private sealed record UiLogEvent(
        string Level,
        string Message,
        string Timestamp,
        string CorrelationId,
        string? UserId,
        string? TenantId,
        string? Route,
        string? Component,
        IReadOnlyDictionary<string, string>? Context,
        UiLogError? Error);

    private sealed record UiLogError(string? Name, string? Message, string? Stack);
}