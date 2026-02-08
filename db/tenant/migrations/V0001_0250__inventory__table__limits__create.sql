-- module: db.tenant.inventory
-- purpose: Create the inventory.limits table for tenant/system subscription limits.
-- exports:
--   - table: inventory.limits
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Limits are stored as JSON objects for flexibility.

create table if not exists inventory.limits (
  limits_id uuid not null default gen_random_uuid(),
  tenant_id uuid not null default core.current_tenant_id(),
  system_id uuid null,
  limits_json jsonb not null default '{}'::jsonb,
  rate_limits_json jsonb not null default '{}'::jsonb,
  flags_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid null,
  updated_by uuid null,
  is_active boolean not null default true,
  constraint limits_pk primary key (limits_id),
  constraint limits_system_fk foreign key (tenant_id, system_id)
    references inventory.system (tenant_id, system_id)
    on delete cascade,
  constraint limits_limits_json_object_check check (jsonb_typeof(limits_json) = 'object'),
  constraint limits_rate_limits_json_object_check check (jsonb_typeof(rate_limits_json) = 'object'),
  constraint limits_flags_json_object_check check (jsonb_typeof(flags_json) = 'object')
);

create unique index if not exists limits_tenant_default_active_ux
  on inventory.limits (tenant_id)
  where system_id is null and is_active = true;

create unique index if not exists limits_tenant_system_active_ux
  on inventory.limits (tenant_id, system_id)
  where system_id is not null and is_active = true;

alter table inventory.limits enable row level security;
alter table inventory.limits force row level security;

create trigger limits_set_updated_at
before update on inventory.limits
for each row
execute function core.set_updated_at();
