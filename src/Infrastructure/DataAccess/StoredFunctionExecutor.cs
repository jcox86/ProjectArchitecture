/*
module: src.infrastructure.dataAccess
purpose: Execute stored functions with Dapper and translate database errors.
exports:
  - class: StoredFunctionExecutor
patterns:
  - dapper_queries
  - error_translation
*/
using System.Data.Common;
using Dapper;
using ProjectArchitecture.Application.DataAccess;

namespace ProjectArchitecture.Infrastructure.DataAccess;

public sealed class StoredFunctionExecutor(PostgresErrorTranslator errorTranslator)
{
    public async Task<T?> QuerySingleOrDefaultAsync<T>(
        DbConnection connection,
        string functionName,
        StoredFunctionParameters parameters,
        CancellationToken cancellationToken)
    {
        var sql = StoredFunction.BuildSetReturning(functionName, parameters.Names);
        var command = new CommandDefinition(sql, parameters.Values, cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleOrDefaultAsync<T>(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw errorTranslator.Translate(ex, "Stored function query", functionName);
        }
    }

    public async Task<T> QuerySingleAsync<T>(
        DbConnection connection,
        string functionName,
        StoredFunctionParameters parameters,
        CancellationToken cancellationToken)
    {
        var sql = StoredFunction.BuildSetReturning(functionName, parameters.Names);
        var command = new CommandDefinition(sql, parameters.Values, cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleAsync<T>(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw errorTranslator.Translate(ex, "Stored function query", functionName);
        }
    }

    public async Task<T?> QueryScalarAsync<T>(
        DbConnection connection,
        string functionName,
        StoredFunctionParameters parameters,
        CancellationToken cancellationToken)
    {
        var sql = StoredFunction.BuildScalar(functionName, parameters.Names);
        var command = new CommandDefinition(sql, parameters.Values, cancellationToken: cancellationToken);

        try
        {
            return await connection.QuerySingleOrDefaultAsync<T>(command);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw errorTranslator.Translate(ex, "Stored function scalar", functionName);
        }
    }
}
