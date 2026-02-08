-- module: db.tenant.bootstrap
-- purpose: Bootstrap the tenant DB schema with required extensions and the core schema.
-- exports:
--   - extension: pgcrypto
--   - extension: citext
--   - schema: core
-- patterns:
--   - flyway_versioned
-- notes:
--   - This migration intentionally groups multiple statements; Flyway executes it atomically (single transaction) on PostgreSQL.

create extension if not exists pgcrypto;
create extension if not exists citext;

create schema if not exists core;

