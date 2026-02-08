/*
module: src.application.idempotency
purpose: Define idempotency request/response records for API retries.
exports:
  - record: IdempotencyRequest
  - record: IdempotencyRecord
  - record: IdempotencyCompletion
  - record: IdempotencyStartResult
  - enum: IdempotencyStartStatus
patterns:
  - idempotency_key
*/
namespace ProjectArchitecture.Application.Idempotency;

public enum IdempotencyStartStatus
{
    Started,
    Completed,
    InProgress,
    Conflict
}

public sealed record IdempotencyRequest(string Key, Guid TenantId, string RequestHash);

public sealed record IdempotencyRecord(int StatusCode, string? ResponseBody, string? ResponseContentType);

public sealed record IdempotencyCompletion(
    string Key,
    Guid TenantId,
    int StatusCode,
    string ResponseBody,
    string? ResponseContentType);

public sealed record IdempotencyStartResult(IdempotencyStartStatus Status, IdempotencyRecord? Record);
