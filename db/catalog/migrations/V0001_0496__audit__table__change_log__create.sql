-- module: db.catalog.audit
-- purpose: Create audit.change_log for record-level history and audit trail.
-- exports:
--   - table: audit.change_log
-- patterns:
--   - flyway_versioned

create table if not exists audit.change_log (
  change_log_id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  tenant_id uuid null references catalog.tenant(tenant_id) on delete set null,
  subject_id uuid null references identity.subject(subject_id) on delete set null,
  change_action_id smallint not null references audit.change_action(change_action_id),
  table_name text not null,
  record_id text not null,
  summary text null,
  before_data jsonb null,
  after_data jsonb null,
  metadata jsonb not null default '{}'::jsonb
);
