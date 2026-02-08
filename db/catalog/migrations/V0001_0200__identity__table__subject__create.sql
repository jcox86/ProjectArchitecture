-- module: db.catalog.identity
-- purpose: Create identity.subject for admin and system principals.
-- exports:
--   - table: identity.subject
-- patterns:
--   - flyway_versioned

create table if not exists identity.subject (
  subject_id uuid primary key default gen_random_uuid(),
  subject_provider_id smallint not null references identity.subject_provider(subject_provider_id),
  external_id text not null,
  display_name text null,
  email citext null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subject_provider_external_unique unique (subject_provider_id, external_id)
);
