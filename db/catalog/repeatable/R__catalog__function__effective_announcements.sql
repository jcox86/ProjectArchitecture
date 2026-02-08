-- module: db.catalog.catalog
-- purpose: Return active announcements merged with tenant overrides for the current tenant context.
-- exports:
--   - function: catalog.effective_announcements()
-- patterns:
--   - flyway_repeatable

create or replace function catalog.effective_announcements()
returns table (
  announcement_id uuid,
  announcement_key text,
  announcement_type_id smallint,
  title text,
  message_html text,
  starts_at timestamptz,
  ends_at timestamptz,
  is_dismissible boolean,
  priority smallint
)
language sql
stable
as $$
  with tenant_context as (
    select nullif(current_setting('app.tenant_id', true), '')::uuid as tenant_id
  ),
  active_status as (
    select announcement_status_id
    from catalog.announcement_status
    where status_key = 'active'
  )
  select
    a.announcement_id,
    a.announcement_key,
    a.announcement_type_id,
    coalesce(o.title, a.title) as title,
    coalesce(o.message_html, a.message_html) as message_html,
    coalesce(o.starts_at, a.starts_at) as starts_at,
    coalesce(o.ends_at, a.ends_at) as ends_at,
    coalesce(o.is_dismissible, a.is_dismissible) as is_dismissible,
    coalesce(o.priority, a.priority) as priority
  from catalog.announcement a
  left join tenant_context tc on true
  left join catalog.announcement_tenant_override o
    on o.announcement_id = a.announcement_id
   and o.tenant_id = tc.tenant_id
  where coalesce(o.announcement_status_id, a.announcement_status_id) in (select announcement_status_id from active_status)
    and (coalesce(o.starts_at, a.starts_at) is null or now() >= coalesce(o.starts_at, a.starts_at))
    and (coalesce(o.ends_at, a.ends_at) is null or now() <= coalesce(o.ends_at, a.ends_at));
$$;
