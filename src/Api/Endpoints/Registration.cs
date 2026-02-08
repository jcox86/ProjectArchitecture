/*
module: src.api.endpoints
purpose: Register API endpoint groups for admin and tenant routes.
exports:
  - extension: RegistrationEndpoints.MapEndpoints(WebApplication)
patterns:
  - minimal_api
*/
using System;
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
}