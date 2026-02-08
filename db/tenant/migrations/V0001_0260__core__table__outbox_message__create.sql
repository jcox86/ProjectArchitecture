-- module: db.tenant.core
-- purpose: Create core.outbox_message for transactional outbox dispatching.
-- exports:
--   - table: core.outbox_message
-- patterns:
--   - flyway_versioned
--   - outbox
--   - rls
-- notes:
--   - RLS policies are defined in repeatable scripts.

create table if not exists core.outbox_message (
  outbox_id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null default core.current_tenant_id(),
  queue_name text not null,
  message_type text not null,
  payload jsonb not null,
  correlation_id text null,
  idempotency_key text null,
  occurred_at timestamptz not null default now(),
  available_at timestamptz not null default now(),
  dispatched_at timestamptz null,
  attempts int not null default 0,
  last_error text null
);

alter table core.outbox_message enable row level security;
alter table core.outbox_message force row level security;

create index if not exists outbox_message_pending_idx
  on core.outbox_message (available_at, occurred_at)
  where dispatched_at is null;

create index if not exists outbox_message_tenant_idx
  on core.outbox_message (tenant_id);
