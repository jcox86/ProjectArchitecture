-- module: db.catalog.audit
-- purpose: Seed lookup data for audit change actions.
-- exports:
--   - seed: audit.change_action
-- patterns:
--   - flyway_seed

insert into audit.change_action (change_action_id, action_key, name, is_active)
values
  (1, 'insert', 'Insert', true),
  (2, 'update', 'Update', true),
  (3, 'delete', 'Delete', true)
on conflict (action_key) do update
set name = excluded.name,
    is_active = excluded.is_active;
