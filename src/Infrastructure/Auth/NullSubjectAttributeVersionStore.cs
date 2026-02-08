/*
module: src.infrastructure.auth
purpose: Provide a no-op ABAC version store when Redis is unavailable.
exports:
  - class: NullSubjectAttributeVersionStore
patterns:
  - abac
*/
using System.Threading;
using System.Threading.Tasks;

namespace ProjectArchitecture.Infrastructure.Auth;

internal sealed class NullSubjectAttributeVersionStore : ISubjectAttributeVersionStore
{
    public Task<long> GetAsync(string versionKey, CancellationToken cancellationToken)
        => Task.FromResult(0L);

    public Task<long> IncrementAsync(string versionKey, CancellationToken cancellationToken)
        => Task.FromResult(0L);
}
