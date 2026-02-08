/*
module: src.infrastructure.dataAccess
purpose: Capture stored-function parameter names and values for consistent Dapper calls.
exports:
  - class: StoredFunctionParameters
patterns:
  - dapper_parameters
*/
using System.Collections.Concurrent;
using System.Reflection;

namespace ProjectArchitecture.Infrastructure.DataAccess;

public sealed class StoredFunctionParameters
{
    private static readonly ConcurrentDictionary<Type, string[]> CachedNames = new();

    private StoredFunctionParameters(object? values, IReadOnlyList<string> names)
    {
        Values = values;
        Names = names;
    }

    public object? Values { get; }

    public IReadOnlyList<string> Names { get; }

    public static StoredFunctionParameters None { get; } = new(null, Array.Empty<string>());

    public static StoredFunctionParameters From(object? values)
    {
        if (values is null)
        {
            return None;
        }

        if (values is StoredFunctionParameters stored)
        {
            return stored;
        }

        if (values is IReadOnlyDictionary<string, object?> dictionary)
        {
            return new StoredFunctionParameters(values, dictionary.Keys.ToArray());
        }

        var names = CachedNames.GetOrAdd(values.GetType(), ResolveNames);
        return new StoredFunctionParameters(values, names);
    }

    private static string[] ResolveNames(Type type)
    {
        return type
            .GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .Select(property => property.Name)
            .ToArray();
    }
}
