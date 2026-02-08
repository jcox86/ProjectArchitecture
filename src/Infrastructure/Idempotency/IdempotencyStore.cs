/*
module: src.infrastructure.idempotency
purpose: Store idempotency keys and responses in the tenant database.
exports:
  - class: IdempotencyStore
patterns:
  - idempotency_key
  - dapper_commands
*/
using Dapper;
using Microsoft.Extensions.Logging;
using ProjectArchitecture.Application.Idempotency;
using ProjectArchitecture.Application.Tenancy;

namespace ProjectArchitecture.Infrastructure.Idempotency;

public sealed class IdempotencyStore(
    ITenantDbConnectionFactory connectionFactory,
    ILogger<IdempotencyStore> logger) : IIdempotencyStore
{
    public async Task<IdempotencyStartResult> TryStartAsync(IdempotencyRequest request, CancellationToken cancellationToken)
    {
        const string insertSql = """
            insert into core.idempotency_key (
              tenant_id,
              idempotency_key,
              request_hash
            )
            values (
              @tenantId,
              @key,
              @hash
            )
            on conflict (tenant_id, idempotency_key) do nothing;
            """;

        const string selectSql = """
            select request_hash as RequestHash,
                   completed_at as CompletedAt,
                   response_status as ResponseStatus,
                   response_body as ResponseBody,
                   response_content_type as ResponseContentType
            from core.idempotency_key
            where tenant_id = @tenantId
              and idempotency_key = @key;
            """;

        try
        {
            await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
            var insertCommand = new CommandDefinition(
                insertSql,
                new { tenantId = request.TenantId, key = request.Key, hash = request.RequestHash },
                cancellationToken: cancellationToken);

            var inserted = await connection.ExecuteAsync(insertCommand);
            if (inserted == 1)
            {
                return new IdempotencyStartResult(IdempotencyStartStatus.Started, null);
            }

            var selectCommand = new CommandDefinition(
                selectSql,
                new { tenantId = request.TenantId, key = request.Key },
                cancellationToken: cancellationToken);

            var existing = await connection.QuerySingleOrDefaultAsync<IdempotencyRecordRow>(selectCommand);
            if (existing is null)
            {
                return new IdempotencyStartResult(IdempotencyStartStatus.Started, null);
            }

            if (!string.Equals(existing.RequestHash, request.RequestHash, StringComparison.Ordinal))
            {
                return new IdempotencyStartResult(IdempotencyStartStatus.Conflict, null);
            }

            if (existing.CompletedAt is not null && existing.ResponseStatus.HasValue)
            {
                var record = new IdempotencyRecord(
                    existing.ResponseStatus.Value,
                    existing.ResponseBody,
                    existing.ResponseContentType);
                return new IdempotencyStartResult(IdempotencyStartStatus.Completed, record);
            }

            return new IdempotencyStartResult(IdempotencyStartStatus.InProgress, null);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to start idempotency key {Key} for tenant {TenantId}.", request.Key, request.TenantId);
            throw;
        }
    }

    public async Task CompleteAsync(IdempotencyCompletion completion, CancellationToken cancellationToken)
    {
        const string sql = """
            update core.idempotency_key
            set completed_at = now(),
                response_status = @status,
                response_body = @body,
                response_content_type = @contentType
            where tenant_id = @tenantId
              and idempotency_key = @key;
            """;

        try
        {
            await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
            var command = new CommandDefinition(
                sql,
                new
                {
                    tenantId = completion.TenantId,
                    key = completion.Key,
                    status = completion.StatusCode,
                    body = completion.ResponseBody,
                    contentType = completion.ResponseContentType
                },
                cancellationToken: cancellationToken);

            await connection.ExecuteAsync(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to complete idempotency key {Key} for tenant {TenantId}.", completion.Key, completion.TenantId);
            throw;
        }
    }

    public async Task RemoveAsync(string key, Guid tenantId, CancellationToken cancellationToken)
    {
        const string sql = """
            delete from core.idempotency_key
            where tenant_id = @tenantId
              and idempotency_key = @key;
            """;

        try
        {
            await using var connection = await connectionFactory.OpenConnectionAsync(cancellationToken);
            var command = new CommandDefinition(
                sql,
                new { tenantId, key },
                cancellationToken: cancellationToken);

            await connection.ExecuteAsync(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to remove idempotency key {Key} for tenant {TenantId}.", key, tenantId);
            throw;
        }
    }

    private sealed record IdempotencyRecordRow(
        string RequestHash,
        DateTimeOffset? CompletedAt,
        int? ResponseStatus,
        string? ResponseBody,
        string? ResponseContentType);
}
