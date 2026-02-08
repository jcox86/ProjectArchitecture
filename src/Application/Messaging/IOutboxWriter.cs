/*
module: src.application.messaging
purpose: Define how transactional outbox entries are persisted.
exports:
  - interface: IOutboxWriter
patterns:
  - outbox
  - sql_first
*/
using System.Data.Common;

namespace ProjectArchitecture.Application.Messaging;

public interface IOutboxWriter
{
    Task EnqueueAsync(
        DbConnection connection,
        DbTransaction transaction,
        OutboxMessage message,
        CancellationToken cancellationToken);
}
