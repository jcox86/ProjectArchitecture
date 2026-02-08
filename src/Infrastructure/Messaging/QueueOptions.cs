/*
module: src.infrastructure.messaging
purpose: Configure Azure Storage Queue connectivity and naming conventions.
exports:
  - options: QueueOptions
patterns:
  - configuration_binding
*/
namespace ProjectArchitecture.Infrastructure.Messaging;

public sealed class QueueOptions
{
    public const string SectionName = "StorageQueues";

    public string ConnectionString { get; init; } = string.Empty;

    public string Prefix { get; init; } = string.Empty;
}
