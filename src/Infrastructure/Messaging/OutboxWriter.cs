/*
module: src.infrastructure.messaging
purpose: Persist outbox messages inside a caller-managed transaction.
exports:
  - class: OutboxWriter
patterns:
  - outbox
  - dapper_commands
*/
using System.Data.Common;
using Dapper;
using Microsoft.Extensions.Logging;
using ProjectArchitecture.Application.Messaging;

namespace ProjectArchitecture.Infrastructure.Messaging;

public sealed class OutboxWriter(ILogger<OutboxWriter> logger) : IOutboxWriter
{
    public async Task EnqueueAsync(
        DbConnection connection,
        DbTransaction transaction,
        OutboxMessage message,
        CancellationToken cancellationToken)
    {
        const string sql = """
            insert into core.outbox_message (
              tenant_id,
              queue_name,
              message_type,
              payload,
              correlation_id,
              idempotency_key,
              available_at
            )
            values (
              @TenantId,
              @QueueName,
              @MessageType,
              @Payload::jsonb,
              @CorrelationId,
              @IdempotencyKey,
              coalesce(@AvailableAt, now())
            );
            """;

        try
        {
            var command = new CommandDefinition(
                sql,
                new
                {
                    message.TenantId,
                    message.QueueName,
                    message.MessageType,
                    message.Payload,
                    message.CorrelationId,
                    message.IdempotencyKey,
                    message.AvailableAt
                },
                transaction: transaction,
                cancellationToken: cancellationToken);

            await connection.ExecuteAsync(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to enqueue outbox message for tenant {TenantId}.", message.TenantId);
            throw;
        }
    }
}
