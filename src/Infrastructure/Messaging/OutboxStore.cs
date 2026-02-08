/*
module: src.infrastructure.messaging
purpose: Read and update pending outbox messages from tenant databases.
exports:
  - class: OutboxStore
patterns:
  - outbox
  - dapper_queries
  - rls
*/
using Dapper;
using Microsoft.Extensions.Logging;
using ProjectArchitecture.Application.Messaging;
using ProjectArchitecture.Application.Tenancy;
using ProjectArchitecture.Domain.Tenancy;
using ProjectArchitecture.Infrastructure.Tenancy;
using Npgsql;

namespace ProjectArchitecture.Infrastructure.Messaging;

public sealed class OutboxStore(
    IPostgresConnectionStringFactory connectionStringFactory,
    ILogger<OutboxStore> logger) : IOutboxStore
{
    public async Task<IReadOnlyList<OutboxRecord>> DequeuePendingAsync(
        TenantCatalogEntry tenant,
        int batchSize,
        CancellationToken cancellationToken)
    {
        const string selectSql = """
            select outbox_id as OutboxId,
                   tenant_id as TenantId,
                   queue_name as QueueName,
                   message_type as MessageType,
                   payload::text as Payload,
                   correlation_id as CorrelationId,
                   idempotency_key as IdempotencyKey,
                   occurred_at as OccurredAt,
                   attempts as Attempts
            from core.outbox_message
            where dispatched_at is null
              and available_at <= @now
            order by occurred_at
            limit @batchSize
            for update skip locked;
            """;

        const string updateAttemptsSql = """
            update core.outbox_message
            set attempts = attempts + 1
            where outbox_id = any(@ids);
            """;

        try
        {
            await using var connection = await OpenTenantConnectionAsync(tenant, cancellationToken);
            await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

            var command = new CommandDefinition(
                selectSql,
                new { now = DateTimeOffset.UtcNow, batchSize },
                transaction: transaction,
                cancellationToken: cancellationToken);

            var records = (await connection.QueryAsync<OutboxRecord>(command)).ToList();
            if (records.Count > 0)
            {
                var updateCommand = new CommandDefinition(
                    updateAttemptsSql,
                    new { ids = records.Select(record => record.OutboxId).ToArray() },
                    transaction: transaction,
                    cancellationToken: cancellationToken);
                await connection.ExecuteAsync(updateCommand);
            }

            await transaction.CommitAsync(cancellationToken);
            return records;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to dequeue outbox messages for tenant {TenantId}.", tenant.TenantId);
            throw;
        }
    }

    public async Task MarkDispatchedAsync(
        TenantCatalogEntry tenant,
        Guid outboxId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            update core.outbox_message
            set dispatched_at = now(),
                last_error = null
            where outbox_id = @outboxId;
            """;

        try
        {
            await using var connection = await OpenTenantConnectionAsync(tenant, cancellationToken);
            var command = new CommandDefinition(sql, new { outboxId }, cancellationToken: cancellationToken);
            await connection.ExecuteAsync(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to mark outbox message {OutboxId} as dispatched.", outboxId);
            throw;
        }
    }

    public async Task MarkFailedAsync(
        TenantCatalogEntry tenant,
        Guid outboxId,
        string error,
        TimeSpan retryDelay,
        CancellationToken cancellationToken)
    {
        const string sql = """
            update core.outbox_message
            set last_error = @error,
                available_at = @availableAt
            where outbox_id = @outboxId;
            """;

        try
        {
            await using var connection = await OpenTenantConnectionAsync(tenant, cancellationToken);
            var command = new CommandDefinition(
                sql,
                new { outboxId, error, availableAt = DateTimeOffset.UtcNow.Add(retryDelay) },
                cancellationToken: cancellationToken);
            await connection.ExecuteAsync(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to mark outbox message {OutboxId} as failed.", outboxId);
            throw;
        }
    }

    private async Task<NpgsqlConnection> OpenTenantConnectionAsync(
        TenantCatalogEntry tenant,
        CancellationToken cancellationToken)
    {
        var connectionString = tenant.Tier switch
        {
            TenantTier.Shared => connectionStringFactory.BuildSharedTenantConnectionString(),
            TenantTier.Isolated when !string.IsNullOrWhiteSpace(tenant.DatabaseName)
                => connectionStringFactory.BuildTenantConnectionString(tenant.DatabaseName, tenant.ServerName),
            _ => throw new InvalidOperationException($"Tenant {tenant.TenantId} has no database mapping.")
        };

        var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        var setTenantCommand = new CommandDefinition(
            "select set_config('app.tenant_id', @tenantId, false);",
            new { tenantId = tenant.TenantId.ToString() },
            cancellationToken: cancellationToken);
        await connection.ExecuteAsync(setTenantCommand);

        return connection;
    }
}
