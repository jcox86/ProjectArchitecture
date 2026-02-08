-- module: db.catalog.billing
-- purpose: Create billing.plan_status lookup for plan lifecycle.
-- exports:
--   - table: billing.plan_status
-- patterns:
--   - flyway_versioned

create table if not exists billing.plan_status (
  plan_status_id smallint primary key,
  status_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint plan_status_key_unique unique (status_key)
);
