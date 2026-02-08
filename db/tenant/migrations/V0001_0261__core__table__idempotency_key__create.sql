-- module: db.tenant.core
-- purpose: Create core.idempotency_key to store request deduplication state.
-- exports:
--   - table: core.idempotency_key
-- patterns:
--   - flyway_versioned
--   - idempotency_key
--   - rls
-- notes:
--   - RLS policies are defined in repeatable scripts.

create table if not exists core.idempotency_key (
  tenant_id uuid not null default core.current_tenant_id(),
  idempotency_key text not null,
  request_hash text not null,
  created_at timestamptz not null default now(),
  completed_at timestamptz null,
  response_status int null,
  response_body text null,
  response_content_type text null,
  constraint idempotency_key_pk primary key (tenant_id, idempotency_key)
);

alter table core.idempotency_key enable row level security;
alter table core.idempotency_key force row level security;

create index if not exists idempotency_key_created_idx
  on core.idempotency_key (created_at);
