-- module: db.tenant.inventory
-- purpose: Create the inventory.system_attachment table for system attachment metadata.
-- exports:
--   - table: inventory.system_attachment
-- patterns:
--   - flyway_versioned
--   - rls
-- notes:
--   - Stores attachment paths and metadata for systems.

create table if not exists inventory.system_attachment (
  tenant_id uuid not null default core.current_tenant_id(),
  attachment_id uuid not null default gen_random_uuid(),
  system_id uuid not null,
  path text not null,
  file_name text null,
  content_type text null,
  size_bytes bigint null,
  metadata jsonb null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid null,
  updated_by uuid null,
  is_active boolean not null default true,
  constraint system_attachment_pk primary key (tenant_id, attachment_id),
  constraint system_attachment_system_fk foreign key (tenant_id, system_id)
    references inventory.system (tenant_id, system_id)
    on delete cascade
);

create index if not exists system_attachment_tenant_system_ix
  on inventory.system_attachment (tenant_id, system_id);

alter table inventory.system_attachment enable row level security;
alter table inventory.system_attachment force row level security;

create trigger system_attachment_set_updated_at
before update on inventory.system_attachment
for each row
execute function core.set_updated_at();
