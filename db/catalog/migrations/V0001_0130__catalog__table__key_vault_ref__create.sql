-- module: db.catalog.catalog
-- purpose: Create catalog.key_vault_ref for logical secret references and scope metadata.
-- exports:
--   - table: catalog.key_vault_ref
-- patterns:
--   - flyway_versioned

create table if not exists catalog.key_vault_ref (
  key_vault_ref_id uuid primary key default gen_random_uuid(),
  tenant_id uuid null references catalog.tenant(tenant_id) on delete cascade,
  key_vault_scope_id smallint not null references catalog.key_vault_scope(key_vault_scope_id),
  name text not null,
  purpose text null,
  secret_uri text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint key_vault_ref_scope_name_unique unique (key_vault_scope_id, name, tenant_id)
);
