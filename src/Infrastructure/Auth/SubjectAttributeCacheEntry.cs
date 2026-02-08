/*
module: src.infrastructure.auth
purpose: Represent cached ABAC attribute payloads stored in Redis.
exports:
  - record: SubjectAttributeCacheEntry
patterns:
  - abac
*/
using System;
using System.Collections.Generic;

namespace ProjectArchitecture.Infrastructure.Auth;

internal sealed record SubjectAttributeCacheEntry(
    long Version,
    SubjectAttributeCachePayload Payload,
    DateTimeOffset CachedAt);

internal sealed record SubjectAttributeCachePayload(
    string[] Permissions,
    string[] Roles,
    Dictionary<string, string> Attributes);
