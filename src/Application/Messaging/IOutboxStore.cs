/*
module: src.application.messaging
purpose: Provide read/update access to pending outbox messages for dispatching.
exports:
  - interface: IOutboxStore
patterns:
  - outbox
*/
using ProjectArchitecture.Application.Tenancy;

namespace ProjectArchitecture.Application.Messaging;

public interface IOutboxStore
{
    Task<IReadOnlyList<OutboxRecord>> DequeuePendingAsync(
        TenantCatalogEntry tenant,
        int batchSize,
        CancellationToken cancellationToken);

    Task MarkDispatchedAsync(
        TenantCatalogEntry tenant,
        Guid outboxId,
        CancellationToken cancellationToken);

    Task MarkFailedAsync(
        TenantCatalogEntry tenant,
        Guid outboxId,
        string error,
        TimeSpan retryDelay,
        CancellationToken cancellationToken);
}
