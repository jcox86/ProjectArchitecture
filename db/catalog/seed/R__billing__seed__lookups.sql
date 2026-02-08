-- module: db.catalog.billing
-- purpose: Seed lookup tables for billing statuses and intervals.
-- exports:
--   - seed: billing.plan_status
--   - seed: billing.price_interval
--   - seed: billing.price_status
--   - seed: billing.addon_status
--   - seed: billing.subscription_status
--   - seed: billing.addon_subscription_status
--   - seed: billing.stripe_customer_status
-- patterns:
--   - flyway_seed

insert into billing.plan_status (plan_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'inactive', 'Inactive', true),
  (3, 'deprecated', 'Deprecated', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.price_interval (price_interval_id, interval_key, name, is_active)
values
  (1, 'month', 'Monthly', true),
  (2, 'year', 'Yearly', true),
  (3, 'one_time', 'One-time', true)
on conflict (interval_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.price_status (price_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'inactive', 'Inactive', true),
  (3, 'deprecated', 'Deprecated', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.addon_status (addon_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'inactive', 'Inactive', true),
  (3, 'deprecated', 'Deprecated', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.subscription_status (subscription_status_id, status_key, name, is_active)
values
  (1, 'trialing', 'Trialing', true),
  (2, 'active', 'Active', true),
  (3, 'past_due', 'Past Due', true),
  (4, 'canceled', 'Canceled', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.addon_subscription_status (addon_subscription_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'past_due', 'Past Due', true),
  (3, 'canceled', 'Canceled', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.stripe_customer_status (stripe_customer_status_id, status_key, name, is_active)
values
  (1, 'active', 'Active', true),
  (2, 'inactive', 'Inactive', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.invoice_status (invoice_status_id, status_key, name, is_active)
values
  (1, 'draft', 'Draft', true),
  (2, 'open', 'Open', true),
  (3, 'paid', 'Paid', true),
  (4, 'void', 'Void', true),
  (5, 'uncollectible', 'Uncollectible', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.payment_status (payment_status_id, status_key, name, is_active)
values
  (1, 'pending', 'Pending', true),
  (2, 'succeeded', 'Succeeded', true),
  (3, 'failed', 'Failed', true),
  (4, 'canceled', 'Canceled', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.refund_status (refund_status_id, status_key, name, is_active)
values
  (1, 'pending', 'Pending', true),
  (2, 'succeeded', 'Succeeded', true),
  (3, 'failed', 'Failed', true),
  (4, 'canceled', 'Canceled', true)
on conflict (status_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.payment_method (payment_method_id, method_key, name, is_active)
values
  (1, 'card', 'Card', true),
  (2, 'bank_transfer', 'Bank Transfer', true),
  (3, 'ach', 'ACH', true),
  (4, 'wire', 'Wire', true),
  (5, 'other', 'Other', true)
on conflict (method_key) do update
set name = excluded.name,
    is_active = excluded.is_active;

insert into billing.invoice_line_type (invoice_line_type_id, type_key, name, is_active)
values
  (1, 'plan', 'Plan', true),
  (2, 'addon', 'Add-on', true),
  (3, 'usage', 'Usage', true),
  (4, 'adjustment', 'Adjustment', true),
  (5, 'tax', 'Tax', true),
  (6, 'discount', 'Discount', true)
on conflict (type_key) do update
set name = excluded.name,
    is_active = excluded.is_active;
