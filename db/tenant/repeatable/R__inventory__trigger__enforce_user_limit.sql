-- module: db.tenant.inventory
-- purpose: Enforce user assignment limits on inventory.system_user_assignment writes.
-- exports:
--   - trigger: inventory.system_user_assignment_enforce_limit
-- patterns:
--   - flyway_repeatable
--   - limits

drop trigger if exists system_user_assignment_enforce_limit
  on inventory.system_user_assignment;

create trigger system_user_assignment_enforce_limit
before insert or update on inventory.system_user_assignment
for each row
execute function inventory.enforce_user_limit();
