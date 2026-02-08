-- module: db.catalog.bootstrap
-- purpose: Bootstrap the catalog DB with required extensions and module schemas.
-- exports:
--   - extension: pgcrypto
--   - extension: citext
--   - schema: catalog
--   - schema: identity
--   - schema: billing
--   - schema: flags
--   - schema: audit
-- patterns:
--   - flyway_versioned
-- notes:
--   - This migration intentionally groups multiple statements; Flyway executes it atomically (single transaction) on PostgreSQL.

create extension if not exists pgcrypto;
create extension if not exists citext;

create schema if not exists catalog;
create schema if not exists identity;
create schema if not exists billing;
create schema if not exists flags;
create schema if not exists audit;

