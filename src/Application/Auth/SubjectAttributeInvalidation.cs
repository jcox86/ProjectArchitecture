/*
module: src.application.auth
purpose: Identify a subject attribute cache entry to invalidate.
exports:
  - record: SubjectAttributeInvalidation
patterns:
  - abac
*/
using System;

namespace ProjectArchitecture.Application.Auth;

public sealed record SubjectAttributeInvalidation(
    string SubjectId,
    Guid? TenantId);
