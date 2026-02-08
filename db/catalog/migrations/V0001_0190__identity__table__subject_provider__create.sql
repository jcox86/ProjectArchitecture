-- module: db.catalog.identity
-- purpose: Create identity.subject_provider lookup for identity providers.
-- exports:
--   - table: identity.subject_provider
-- patterns:
--   - flyway_versioned

create table if not exists identity.subject_provider (
  subject_provider_id smallint primary key,
  provider_key text not null,
  name text not null,
  is_active boolean not null default true,
  constraint subject_provider_key_unique unique (provider_key)
);
