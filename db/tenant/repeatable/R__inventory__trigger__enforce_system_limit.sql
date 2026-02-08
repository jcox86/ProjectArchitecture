-- module: db.tenant.inventory
-- purpose: Enforce system limits on inventory.system writes.
-- exports:
--   - trigger: inventory.system_enforce_limit
-- patterns:
--   - flyway_repeatable
--   - limits

drop trigger if exists system_enforce_limit on inventory.system;

create trigger system_enforce_limit
before insert or update on inventory.system
for each row
execute function inventory.enforce_system_limit();
