-- module: db.catalog.catalog
-- purpose: Create catalog.tenant_tier lookup for tenant tier values.
-- exports:
--   - table: catalog.tenant_tier
-- patterns:
--   - flyway_versioned

create table if not exists catalog.tenant_tier (
  tenant_tier_id smallint primary key,
  tier_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint tenant_tier_key_unique unique (tier_key)
);
