-- module: db.catalog.flags
-- purpose: Create flags.flag_tenant_override for per-tenant flag settings.
-- exports:
--   - table: flags.flag_tenant_override
-- patterns:
--   - flyway_versioned

create table if not exists flags.flag_tenant_override (
  flag_tenant_override_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  flag_id uuid not null references flags.flag(flag_id) on delete cascade,
  is_enabled boolean null,
  config jsonb null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint flag_tenant_override_unique unique (tenant_id, flag_id)
);
