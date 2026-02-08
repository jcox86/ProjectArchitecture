-- module: db.catalog.audit
-- purpose: Create audit.event to capture control-plane audit logs.
-- exports:
--   - table: audit.event
-- patterns:
--   - flyway_versioned

create table if not exists audit.event (
  event_id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  tenant_id uuid null references catalog.tenant(tenant_id) on delete set null,
  subject_id uuid null references identity.subject(subject_id) on delete set null,
  action text not null,
  entity_type text null,
  entity_id text null,
  event_severity_id smallint not null references audit.event_severity(event_severity_id),
  ip_address inet null,
  user_agent text null,
  data jsonb not null default '{}'::jsonb
);
