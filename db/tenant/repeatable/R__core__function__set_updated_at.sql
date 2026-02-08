-- module: db.tenant.core
-- purpose: Define a shared trigger function to automatically set `updated_at` on row updates.
-- exports:
--   - function: core.set_updated_at()
-- patterns:
--   - flyway_repeatable
-- notes:
--   - Inspired by common SaaS starter schemas; attach via a BEFORE UPDATE trigger per table.

create or replace function core.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

