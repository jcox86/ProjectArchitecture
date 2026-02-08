/*
module: src.infrastructure.dataAccess
purpose: Translate Npgsql/Postgres errors into standardized data access exceptions.
exports:
  - class: PostgresErrorTranslator
patterns:
  - error_translation
*/
using Npgsql;
using ProjectArchitecture.Application.DataAccess;

namespace ProjectArchitecture.Infrastructure.DataAccess;

public sealed class PostgresErrorTranslator
{
    public DataAccessException Translate(Exception exception, string operation, string? functionName)
    {
        if (exception is DataAccessException alreadyTranslated)
        {
            return alreadyTranslated;
        }

        if (exception is PostgresException postgres)
        {
            var kind = MapSqlState(postgres.SqlState);
            return new DataAccessException(kind, operation, functionName, postgres.SqlState, postgres);
        }

        if (exception is NpgsqlException npgsql)
        {
            return new DataAccessException(DataAccessErrorKind.Transient, operation, functionName, null, npgsql);
        }

        return new DataAccessException(DataAccessErrorKind.Unknown, operation, functionName, null, exception);
    }

    private static DataAccessErrorKind MapSqlState(string? sqlState)
    {
        return sqlState switch
        {
            "P0002" => DataAccessErrorKind.NotFound,
            "23505" => DataAccessErrorKind.Conflict,
            "23503" => DataAccessErrorKind.Validation,
            "23514" => DataAccessErrorKind.Validation,
            "23502" => DataAccessErrorKind.Validation,
            "22001" => DataAccessErrorKind.Validation,
            "40001" => DataAccessErrorKind.Transient,
            "40P01" => DataAccessErrorKind.Transient,
            "53300" => DataAccessErrorKind.Transient,
            "57014" => DataAccessErrorKind.Transient,
            _ => DataAccessErrorKind.Unknown
        };
    }
}
