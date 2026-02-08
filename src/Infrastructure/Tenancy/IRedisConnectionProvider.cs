/*
module: src.infrastructure.tenancy
purpose: Provide optional access to a shared Redis connection.
exports:
  - interface: IRedisConnectionProvider
patterns:
  - dependency_inversion
*/
using StackExchange.Redis;

namespace ProjectArchitecture.Infrastructure.Tenancy;

internal interface IRedisConnectionProvider
{
    IConnectionMultiplexer? Multiplexer { get; }
}
