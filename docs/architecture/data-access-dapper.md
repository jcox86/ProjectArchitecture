<!--
module: docs.architecture.dataAccess
purpose: Describe Dapper and stored-function conventions for catalog and tenant databases.
exports:
  - doc: data_access_dapper_conventions
patterns:
  - dapper_conventions
  - stored_function_calls
-->

# Data access conventions (Dapper + stored functions)

These conventions apply to both the **catalog** and **tenant** PostgreSQL databases.

## Stored function usage

- Use stored functions for application reads/writes where possible.
- For set-returning functions, call them as `select * from schema.function(@param, ...)`.
- For scalar functions, call them as `select schema.function(@param, ...)`.
- Always pass named parameters (no positional arguments).

Use the shared helpers in `ProjectArchitecture.Infrastructure.DataAccess`:

```csharp
var result = await storedFunctionExecutor.QuerySingleOrDefaultAsync<MyDto>(
    connection,
    "catalog.resolve_tenant_by_host",
    StoredFunctionParameters.From(new { host }),
    cancellationToken);
```

## DTO mapping

- Prefer `snake_case` column names from SQL.
- Dapper is configured with `MatchNamesWithUnderscores = true`, so `tenant_id` maps to `TenantId`.
- When returning computed columns, alias to `snake_case` so mapping stays consistent.

## Error translation

- Database exceptions are translated into `DataAccessException`.
- Map common Postgres SQLSTATE values to error kinds:
  - `23505` → `Conflict`
  - `23503`, `23514`, `23502`, `22001` → `Validation`
  - `40001`, `40P01`, `53300`, `57014` → `Transient`
  - `P0002` → `NotFound`
- Callers should log the exception and return safe error messages.

Example scalar call (tenant DB):

```csharp
var tenantId = await storedFunctionExecutor.QueryScalarAsync<Guid?>(
    connection,
    "core.current_tenant_id",
    StoredFunctionParameters.None,
    cancellationToken);
```
