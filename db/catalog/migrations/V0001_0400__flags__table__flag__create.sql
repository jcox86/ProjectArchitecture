-- module: db.catalog.flags
-- purpose: Create flags.flag for global feature flag definitions.
-- exports:
--   - table: flags.flag
-- patterns:
--   - flyway_versioned

create table if not exists flags.flag (
  flag_id uuid primary key default gen_random_uuid(),
  flag_key text not null,
  name text not null,
  description text null,
  flag_scope_id smallint not null references flags.flag_scope(flag_scope_id),
  flag_status_id smallint not null references flags.flag_status(flag_status_id),
  is_enabled boolean not null default false,
  config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint flag_key_unique unique (flag_key)
);
