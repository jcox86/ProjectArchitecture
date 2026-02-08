/*
module: src.application.dataAccess
purpose: Define standardized data access errors for database operations.
exports:
  - enum: DataAccessErrorKind
  - exception: DataAccessException
patterns:
  - data_access
*/
namespace ProjectArchitecture.Application.DataAccess;

public enum DataAccessErrorKind
{
    Unknown,
    NotFound,
    Conflict,
    Validation,
    Transient
}

public sealed class DataAccessException : Exception
{
    public DataAccessException(
        DataAccessErrorKind kind,
        string operation,
        string? functionName,
        string? sqlState,
        Exception innerException)
        : base(BuildMessage(kind, operation), innerException)
    {
        Kind = kind;
        Operation = operation;
        FunctionName = functionName;
        SqlState = sqlState;
    }

    public DataAccessErrorKind Kind { get; }

    public string Operation { get; }

    public string? FunctionName { get; }

    public string? SqlState { get; }

    private static string BuildMessage(DataAccessErrorKind kind, string operation)
    {
        return kind switch
        {
            DataAccessErrorKind.NotFound => $"{operation} returned no data.",
            DataAccessErrorKind.Conflict => $"{operation} conflicted with existing data.",
            DataAccessErrorKind.Validation => $"{operation} was rejected by the database.",
            DataAccessErrorKind.Transient => $"{operation} could not be completed. Retry the operation.",
            _ => $"{operation} failed."
        };
    }
}
