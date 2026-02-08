/*
module: src.api.middleware
purpose: Enforce idempotency keys for write requests and replay stored responses.
exports:
  - middleware: IdempotencyMiddleware
patterns:
  - idempotency_key
  - minimal_api
*/
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using ProjectArchitecture.Application.Idempotency;
using ProjectArchitecture.Application.Tenancy;

namespace ProjectArchitecture.Api.Middleware;

public sealed class IdempotencyMiddleware(
    RequestDelegate next,
    IIdempotencyStore idempotencyStore,
    ITenantContextAccessor tenantContextAccessor,
    IOptions<IdempotencyOptions> options,
    ILogger<IdempotencyMiddleware> logger)
{
    private readonly IdempotencyOptions _options = options.Value;

    public async Task InvokeAsync(HttpContext context)
    {
        if (!ShouldApply(context))
        {
            await next(context);
            return;
        }

        var tenant = tenantContextAccessor.Current?.Tenant;
        if (tenant is null)
        {
            await next(context);
            return;
        }

        if (!context.Request.Headers.TryGetValue("Idempotency-Key", out var idempotencyKeyValues))
        {
            await next(context);
            return;
        }

        var idempotencyKey = idempotencyKeyValues.ToString().Trim();
        if (string.IsNullOrWhiteSpace(idempotencyKey))
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsync("Missing Idempotency-Key header.");
            return;
        }

        context.Response.Headers["Idempotency-Key"] = idempotencyKey;

        if (context.Request.ContentLength is > 0 and > int.MaxValue)
        {
            context.Response.StatusCode = StatusCodes.Status413PayloadTooLarge;
            await context.Response.WriteAsync("Request payload is too large for idempotency.");
            return;
        }

        if (_options.MaxBodyBytes > 0 && context.Request.ContentLength is long length && length > _options.MaxBodyBytes)
        {
            context.Response.StatusCode = StatusCodes.Status413PayloadTooLarge;
            await context.Response.WriteAsync("Request payload is too large for idempotency.");
            return;
        }

        try
        {
            var requestBody = await ReadRequestBodyAsync(context, context.RequestAborted);
            var requestHash = ComputeHash(context.Request.Method, context.Request.Path, context.Request.QueryString, requestBody);

            var request = new IdempotencyRequest(idempotencyKey, tenant.TenantId, requestHash);
            var startResult = await idempotencyStore.TryStartAsync(request, context.RequestAborted);
            if (startResult.Status == IdempotencyStartStatus.Completed && startResult.Record is not null)
            {
                await WriteStoredResponseAsync(context, startResult.Record);
                return;
            }

            if (startResult.Status == IdempotencyStartStatus.Conflict)
            {
                context.Response.StatusCode = StatusCodes.Status409Conflict;
                await context.Response.WriteAsync("Idempotency key was used with a different request.");
                return;
            }

            if (startResult.Status == IdempotencyStartStatus.InProgress)
            {
                context.Response.StatusCode = StatusCodes.Status409Conflict;
                await context.Response.WriteAsync("Request is already in progress.");
                return;
            }

            var originalBody = context.Response.Body;
            await using var buffer = new MemoryStream();
            context.Response.Body = buffer;

            try
            {
                await next(context);
            }
            finally
            {
                context.Response.Body = originalBody;
            }

            buffer.Position = 0;
            var responseBody = await new StreamReader(buffer, Encoding.UTF8).ReadToEndAsync(context.RequestAborted);
            buffer.Position = 0;
            await buffer.CopyToAsync(originalBody, context.RequestAborted);

            if (IsSuccessStatus(context.Response.StatusCode))
            {
                if (_options.MaxResponseBytes <= 0 || responseBody.Length <= _options.MaxResponseBytes)
                {
                    var completion = new IdempotencyCompletion(
                        idempotencyKey,
                        tenant.TenantId,
                        context.Response.StatusCode,
                        responseBody,
                        context.Response.ContentType);
                    await idempotencyStore.CompleteAsync(completion, context.RequestAborted);
                }
                else
                {
                    logger.LogWarning(
                        "Idempotency response exceeds max size for tenant {TenantId} and key {Key}.",
                        tenant.TenantId,
                        idempotencyKey);
                    await idempotencyStore.RemoveAsync(idempotencyKey, tenant.TenantId, context.RequestAborted);
                }
            }
            else
            {
                await idempotencyStore.RemoveAsync(idempotencyKey, tenant.TenantId, context.RequestAborted);
            }
        }
        catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Idempotency handling failed for {Path}.", context.Request.Path);
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsync("Idempotency handling failed.");
        }
    }

    private bool ShouldApply(HttpContext context)
    {
        if (!_options.Enabled)
        {
            return false;
        }

        return HttpMethods.IsPost(context.Request.Method)
            || HttpMethods.IsPut(context.Request.Method)
            || HttpMethods.IsPatch(context.Request.Method)
            || HttpMethods.IsDelete(context.Request.Method);
    }

    private static async Task<string> ReadRequestBodyAsync(HttpContext context, CancellationToken cancellationToken)
    {
        context.Request.EnableBuffering();
        using var reader = new StreamReader(context.Request.Body, Encoding.UTF8, leaveOpen: true);
        var body = await reader.ReadToEndAsync(cancellationToken);
        context.Request.Body.Position = 0;
        return body;
    }

    private static string ComputeHash(string method, PathString path, QueryString query, string body)
    {
        var payload = $"{method}\n{path}{query}\n{body}";
        using var sha = SHA256.Create();
        var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(bytes);
    }

    private static async Task WriteStoredResponseAsync(HttpContext context, IdempotencyRecord record)
    {
        context.Response.StatusCode = record.StatusCode;
        if (!string.IsNullOrWhiteSpace(record.ResponseContentType))
        {
            context.Response.ContentType = record.ResponseContentType;
        }

        if (!string.IsNullOrWhiteSpace(record.ResponseBody))
        {
            await context.Response.WriteAsync(record.ResponseBody);
        }
    }

    private static bool IsSuccessStatus(int statusCode)
        => statusCode is >= 200 and < 300;
}
