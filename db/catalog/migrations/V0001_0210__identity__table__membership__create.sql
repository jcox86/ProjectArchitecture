-- module: db.catalog.identity
-- purpose: Create identity.membership mapping subjects to tenant roles.
-- exports:
--   - table: identity.membership
-- patterns:
--   - flyway_versioned

create table if not exists identity.membership (
  membership_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references catalog.tenant(tenant_id) on delete cascade,
  subject_id uuid not null references identity.subject(subject_id) on delete cascade,
  membership_role_id smallint not null references identity.membership_role(membership_role_id),
  membership_status_id smallint not null references identity.membership_status(membership_status_id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint membership_unique unique (tenant_id, subject_id, membership_role_id)
);
