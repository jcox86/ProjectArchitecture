/*
module: src.application.auth
purpose: Describe the request for resolving subject attributes.
exports:
  - record: SubjectAttributeRequest
patterns:
  - abac
*/
using System;
using System.Security.Claims;

namespace ProjectArchitecture.Application.Auth;

public sealed record SubjectAttributeRequest(
    ClaimsPrincipal Principal,
    Guid? TenantId,
    string? Scheme);
