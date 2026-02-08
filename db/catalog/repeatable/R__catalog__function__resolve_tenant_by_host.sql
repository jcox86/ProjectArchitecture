-- module: db.catalog.catalog
-- purpose: Resolve tenant identity and tier by host for routing decisions.
-- exports:
--   - function: catalog.resolve_tenant_by_host(citext)
-- patterns:
--   - flyway_repeatable

create or replace function catalog.resolve_tenant_by_host(p_host citext)
returns table (tenant_id uuid, tenant_key citext, tenant_tier_id smallint, tenant_status_id smallint)
language sql
stable
as $$
  select t.tenant_id, t.tenant_key, t.tenant_tier_id, t.tenant_status_id
  from catalog.tenant t
  join catalog.tenant_route r on r.tenant_id = t.tenant_id
  join catalog.tenant_route_status rs on rs.tenant_route_status_id = r.tenant_route_status_id
  join catalog.tenant_status ts on ts.tenant_status_id = t.tenant_status_id
  where r.host_name = p_host
    and rs.status_key = 'active'
    and ts.status_key = 'active';
$$;
