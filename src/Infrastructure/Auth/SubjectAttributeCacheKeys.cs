/*
module: src.infrastructure.auth
purpose: Build Redis cache keys for ABAC attributes and versions.
exports:
  - class: SubjectAttributeCacheKeys
patterns:
  - abac
*/
namespace ProjectArchitecture.Infrastructure.Auth;

internal static class SubjectAttributeCacheKeys
{
    public static string Attributes(string prefix, string subjectId, string? tenantKey)
        => $"{prefix}:attr:{subjectId}:{tenantKey ?? "global"}";

    public static string Version(string prefix, string subjectId, string? tenantKey)
        => $"{prefix}:ver:{subjectId}:{tenantKey ?? "global"}";
}
