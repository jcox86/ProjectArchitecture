-- module: db.tenant.inventory
-- purpose: Enforce item limits on inventory.item writes.
-- exports:
--   - trigger: inventory.item_enforce_limit
-- patterns:
--   - flyway_repeatable
--   - limits

drop trigger if exists item_enforce_limit on inventory.item;

create trigger item_enforce_limit
before insert or update on inventory.item
for each row
execute function inventory.enforce_item_limit();
