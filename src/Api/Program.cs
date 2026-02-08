/*
module: src.api
purpose: Configure the API host, dependencies, and HTTP pipeline.
exports:
  - app: ApiHost
patterns:
  - minimal_api
*/
using ProjectArchitecture.Api.Auth;
using ProjectArchitecture.Api.Endpoints;
using ProjectArchitecture.Api.Middleware;
using ProjectArchitecture.Infrastructure;
using Serilog;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

try
{
    // Add services to the container.
    // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
    builder.AddServiceDefaults();
    builder.Services.AddOpenApi();
    builder.Services.AddInfrastructure(builder.Configuration);
    builder.Services.AddApiAuthentication(builder.Configuration, builder.Environment);
    builder.Services.Configure<IdempotencyOptions>(builder.Configuration.GetSection(IdempotencyOptions.SectionName));

    // Add Scalar API reference
    // Add Security
    // Add Caching
    // Security Headers

    var app = builder.Build();

    // Configure the HTTP request pipeline.
    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();
        app.MapScalarApiReference("/", options =>
        {
            options.WithTitle("Project API");
        });
    }

    app.UseHttpsRedirection();
    app.UseAuthentication();
    app.UseMiddleware<TenantResolutionMiddleware>();
    app.UseMiddleware<CorrelationContextMiddleware>();
    app.UseAuthorization();
    app.UseMiddleware<IdempotencyMiddleware>();

    app.MapEndpoints();
    app.MapDefaultEndpoints();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "API host terminated unexpectedly.");
}
finally
{
    Log.Information("API stopped");
    Log.CloseAndFlush();
}

public partial class Program { }