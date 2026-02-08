/*
module: src.worker
purpose: Configure polling and retry behavior for outbox dispatching.
exports:
  - options: OutboxDispatcherOptions
patterns:
  - outbox
*/
namespace ProjectArchitecture.Worker;

public sealed class OutboxDispatcherOptions
{
    public const string SectionName = "OutboxDispatcher";

    public int BatchSize { get; init; } = 25;

    public int PollDelaySeconds { get; init; } = 2;

    public int RetryDelaySeconds { get; init; } = 10;

    public int MaxAttempts { get; init; } = 10;
}
