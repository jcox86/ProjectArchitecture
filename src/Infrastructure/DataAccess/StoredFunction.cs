/*
module: src.infrastructure.dataAccess
purpose: Build consistent SQL for stored-function calls.
exports:
  - static: StoredFunction.BuildSetReturning(string, IReadOnlyList<string>)
  - static: StoredFunction.BuildScalar(string, IReadOnlyList<string>)
patterns:
  - stored_function_calls
*/
namespace ProjectArchitecture.Infrastructure.DataAccess;

public static class StoredFunction
{
    public static string BuildSetReturning(string functionName, IReadOnlyList<string> parameterNames)
        => Build("select * from", functionName, parameterNames);

    public static string BuildScalar(string functionName, IReadOnlyList<string> parameterNames)
        => Build("select", functionName, parameterNames);

    private static string Build(string prefix, string functionName, IReadOnlyList<string> parameterNames)
    {
        if (string.IsNullOrWhiteSpace(functionName))
        {
            throw new ArgumentException("Function name is required.", nameof(functionName));
        }

        var parameters = parameterNames.Count switch
        {
            0 => string.Empty,
            _ => string.Join(", ", parameterNames.Select(name => $"@{Normalize(name)}"))
        };

        return $"{prefix} {functionName}({parameters});";
    }

    private static string Normalize(string name)
        => name.StartsWith('@') ? name[1..] : name;
}
