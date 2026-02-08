/*
module: src.application.auth
purpose: Resolve attribute-based access control data for a subject.
exports:
  - interface: ISubjectAttributeProvider
patterns:
  - abac
*/
using System.Threading;
using System.Threading.Tasks;

namespace ProjectArchitecture.Application.Auth;

public interface ISubjectAttributeProvider
{
    Task<SubjectAttributes> GetAttributesAsync(SubjectAttributeRequest request, CancellationToken cancellationToken);
}
