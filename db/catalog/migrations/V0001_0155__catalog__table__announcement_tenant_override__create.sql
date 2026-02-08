-- module: db.catalog.catalog
-- purpose: Create catalog.announcement_tenant_override for tenant-specific overrides.
-- exports:
--   - table: catalog.announcement_tenant_override
-- patterns:
--   - flyway_versioned

create table if not exists catalog.announcement_tenant_override (
  announcement_tenant_override_id uuid primary key default gen_random_uuid(),
  announcement_id uuid not null references catalog.announcement(announcement_id) on delete cascade,
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  announcement_status_id smallint null references catalog.announcement_status(announcement_status_id),
  title text null,
  message_html text null,
  starts_at timestamptz null,
  ends_at timestamptz null,
  is_dismissible boolean null,
  priority smallint null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint announcement_tenant_override_unique unique (tenant_id, announcement_id)
);
