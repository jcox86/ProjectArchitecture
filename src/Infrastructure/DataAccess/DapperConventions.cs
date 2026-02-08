/*
module: src.infrastructure.dataAccess
purpose: Configure global Dapper conventions for DTO mapping.
exports:
  - static: DapperConventions.Configure()
patterns:
  - dapper_conventions
*/
using Dapper;

namespace ProjectArchitecture.Infrastructure.DataAccess;

internal static class DapperConventions
{
    private static bool _configured;

    public static void Configure()
    {
        if (_configured)
        {
            return;
        }

        DefaultTypeMap.MatchNamesWithUnderscores = true;
        _configured = true;
    }
}
