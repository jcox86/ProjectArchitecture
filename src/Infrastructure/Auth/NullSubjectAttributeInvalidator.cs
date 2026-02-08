/*
module: src.infrastructure.auth
purpose: Provide a no-op ABAC invalidator when Redis is unavailable.
exports:
  - class: NullSubjectAttributeInvalidator
patterns:
  - abac
*/
using System.Threading;
using System.Threading.Tasks;
using ProjectArchitecture.Application.Auth;

namespace ProjectArchitecture.Infrastructure.Auth;

public sealed class NullSubjectAttributeInvalidator : ISubjectAttributeInvalidator
{
    public Task InvalidateAsync(SubjectAttributeInvalidation invalidation, CancellationToken cancellationToken)
        => Task.CompletedTask;
}
