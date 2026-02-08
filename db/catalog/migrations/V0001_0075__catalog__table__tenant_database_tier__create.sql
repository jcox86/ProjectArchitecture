-- module: db.catalog.catalog
-- purpose: Create catalog.tenant_database_tier lookup for data-plane tiers.
-- exports:
--   - table: catalog.tenant_database_tier
-- patterns:
--   - flyway_versioned

create table if not exists catalog.tenant_database_tier (
  tenant_database_tier_id smallint primary key,
  tier_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint tenant_database_tier_key_unique unique (tier_key)
);
