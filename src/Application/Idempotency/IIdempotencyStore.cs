/*
module: src.application.idempotency
purpose: Provide persistence for idempotency keys and responses.
exports:
  - interface: IIdempotencyStore
patterns:
  - idempotency_key
*/
namespace ProjectArchitecture.Application.Idempotency;

public interface IIdempotencyStore
{
    Task<IdempotencyStartResult> TryStartAsync(IdempotencyRequest request, CancellationToken cancellationToken);

    Task CompleteAsync(IdempotencyCompletion completion, CancellationToken cancellationToken);

    Task RemoveAsync(string key, Guid tenantId, CancellationToken cancellationToken);
}
