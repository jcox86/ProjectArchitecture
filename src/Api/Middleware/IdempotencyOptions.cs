/*
module: src.api.middleware
purpose: Configure idempotency middleware behavior for write endpoints.
exports:
  - options: IdempotencyOptions
patterns:
  - idempotency_key
*/
namespace ProjectArchitecture.Api.Middleware;

public sealed class IdempotencyOptions
{
    public const string SectionName = "Idempotency";

    public bool Enabled { get; init; } = true;

    public int MaxBodyBytes { get; init; } = 262144;

    public int MaxResponseBytes { get; init; } = 262144;
}
