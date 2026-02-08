/*
module: src.worker
purpose: Configure queue processing behavior for the worker.
exports:
  - options: QueueProcessorOptions
patterns:
  - storage_queues
*/
namespace ProjectArchitecture.Worker;

public sealed class QueueProcessorOptions
{
    public const string SectionName = "QueueProcessor";

    public string[] Queues { get; init; } = Array.Empty<string>();

    public int BatchSize { get; init; } = 16;

    public int PollDelaySeconds { get; init; } = 2;

    public int VisibilityTimeoutSeconds { get; init; } = 30;

    public int MaxDequeueCount { get; init; } = 5;

    public int PoisonMessageTtlDays { get; init; } = 7;
}
