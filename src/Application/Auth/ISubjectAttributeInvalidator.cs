/*
module: src.application.auth
purpose: Invalidate cached subject attributes for ABAC policies.
exports:
  - interface: ISubjectAttributeInvalidator
patterns:
  - abac
*/
using System.Threading;
using System.Threading.Tasks;

namespace ProjectArchitecture.Application.Auth;

public interface ISubjectAttributeInvalidator
{
    Task InvalidateAsync(SubjectAttributeInvalidation invalidation, CancellationToken cancellationToken);
}
