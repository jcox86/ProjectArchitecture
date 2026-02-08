-- module: db.tenant.inventory
-- purpose: Provide verification checks for inventory schema RLS and constraints.
-- exports:
--   - function: inventory.verify_schema()
-- patterns:
--   - flyway_repeatable
--   - rls
--   - verification
-- notes:
--   - Returns rows describing violations; an empty result means checks pass.

create or replace function inventory.verify_schema()
returns table (check_name text, detail text)
language sql
as $$
  with checks as (
    select
      'inventory.tenant_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'tenant'

    union all
    select
      'inventory.system_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'system'

    union all
    select
      'inventory.item_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'item'

    union all
    select
      'inventory.tenant_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'tenant'
            and p.polname = 'tenant_tenant_isolation'
        )
        then null
        else 'RLS policy tenant_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.system_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'system'
            and p.polname = 'system_tenant_isolation'
        )
        then null
        else 'RLS policy system_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.item_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'item'
            and p.polname = 'item_tenant_isolation'
        )
        then null
        else 'RLS policy item_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.tenant_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'tenant'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.tenant'
      end as detail

    union all
    select
      'inventory.tenant_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'tenant'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.tenant'
      end as detail

    union all
    select
      'inventory.tenant_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'tenant'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.tenant'
      end as detail

    union all
    select
      'inventory.system_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.system'
      end as detail

    union all
    select
      'inventory.system_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.system'
      end as detail

    union all
    select
      'inventory.system_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.system'
      end as detail

    union all
    select
      'inventory.item_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.item'
      end as detail

    union all
    select
      'inventory.item_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.item'
      end as detail

    union all
    select
      'inventory.item_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.item'
      end as detail

    union all
    select
      'inventory.item_template_id_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item'
            and col.column_name = 'template_id'
        )
        then null
        else 'Column template_id missing on inventory.item'
      end as detail

    union all
    select
      'inventory.tenant_default_system_id_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'tenant'
            and col.column_name = 'default_system_id'
        )
        then null
        else 'Column default_system_id missing on inventory.tenant'
      end as detail

    union all
    select
      'inventory.tenant_default_system_fk' as check_name,
      case
        when exists (
          select 1
          from pg_constraint con
          join pg_class c on c.oid = con.conrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'tenant'
            and con.conname = 'tenant_default_system_fk'
        )
        then null
        else 'Foreign key tenant_default_system_fk missing'
      end as detail

    union all
    select
      'inventory.tenant_default_system_trigger' as check_name,
      case
        when exists (
          select 1
          from pg_trigger t
          join pg_class c on c.oid = t.tgrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'tenant'
            and t.tgname = 'tenant_default_system'
            and not t.tgisinternal
        )
        then null
        else 'Trigger tenant_default_system missing'
      end as detail

    union all
    select
      'inventory.tenant_default_system_function' as check_name,
      case
        when exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'inventory'
            and p.proname = 'create_default_system_for_tenant'
        )
        then null
        else 'Function inventory.create_default_system_for_tenant missing'
      end as detail

    union all
    select
      'inventory.system_user_assignment_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'system_user_assignment'

    union all
    select
      'inventory.system_attachment_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'system_attachment'

    union all
    select
      'inventory.item_template_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'item_template'

    union all
    select
      'inventory.item_template_field_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'item_template_field'

    union all
    select
      'inventory.item_property_definition_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'item_property_definition'

    union all
    select
      'inventory.item_property_value_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'item_property_value'

    union all
    select
      'inventory.system_user_assignment_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'system_user_assignment'
            and p.polname = 'system_user_assignment_tenant_isolation'
        )
        then null
        else 'RLS policy system_user_assignment_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.system_attachment_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'system_attachment'
            and p.polname = 'system_attachment_tenant_isolation'
        )
        then null
        else 'RLS policy system_attachment_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.limits_rls' as check_name,
      case
        when c.relrowsecurity and c.relforcerowsecurity then null
        else 'RLS not enabled and forced'
      end as detail
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'inventory' and c.relname = 'limits'

    union all
    select
      'inventory.limits_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'limits'
            and p.polname = 'limits_tenant_isolation'
        )
        then null
        else 'RLS policy limits_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.item_template_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'item_template'
            and p.polname = 'item_template_tenant_isolation'
        )
        then null
        else 'RLS policy item_template_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.item_template_field_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'item_template_field'
            and p.polname = 'item_template_field_tenant_isolation'
        )
        then null
        else 'RLS policy item_template_field_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.item_property_definition_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'item_property_definition'
            and p.polname = 'item_property_definition_tenant_isolation'
        )
        then null
        else 'RLS policy item_property_definition_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.item_property_value_policy' as check_name,
      case
        when exists (
          select 1
          from pg_policy p
          join pg_class c on c.oid = p.polrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'item_property_value'
            and p.polname = 'item_property_value_tenant_isolation'
        )
        then null
        else 'RLS policy item_property_value_tenant_isolation missing'
      end as detail

    union all
    select
      'inventory.system_user_assignment_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system_user_assignment'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.system_user_assignment'
      end as detail

    union all
    select
      'inventory.system_user_assignment_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system_user_assignment'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.system_user_assignment'
      end as detail

    union all
    select
      'inventory.system_user_assignment_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system_user_assignment'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.system_user_assignment'
      end as detail

    union all
    select
      'inventory.system_attachment_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system_attachment'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.system_attachment'
      end as detail

    union all
    select
      'inventory.system_attachment_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system_attachment'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.system_attachment'
      end as detail

    union all
    select
      'inventory.system_attachment_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'system_attachment'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.system_attachment'
      end as detail

    union all
    select
      'inventory.limits_limits_json_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'limits'
            and col.column_name = 'limits_json'
        )
        then null
        else 'Column limits_json missing on inventory.limits'
      end as detail

    union all
    select
      'inventory.limits_rate_limits_json_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'limits'
            and col.column_name = 'rate_limits_json'
        )
        then null
        else 'Column rate_limits_json missing on inventory.limits'
      end as detail

    union all
    select
      'inventory.limits_flags_json_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'limits'
            and col.column_name = 'flags_json'
        )
        then null
        else 'Column flags_json missing on inventory.limits'
      end as detail

    union all
    select
      'inventory.limits_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'limits'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.limits'
      end as detail

    union all
    select
      'inventory.limits_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'limits'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.limits'
      end as detail

    union all
    select
      'inventory.limits_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'limits'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.limits'
      end as detail

    union all
    select
      'inventory.limits_limits_json_constraint' as check_name,
      case
        when exists (
          select 1
          from pg_constraint con
          join pg_class c on c.oid = con.conrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'limits'
            and con.conname = 'limits_limits_json_object_check'
        )
        then null
        else 'Constraint limits_limits_json_object_check missing'
      end as detail

    union all
    select
      'inventory.limits_rate_limits_json_constraint' as check_name,
      case
        when exists (
          select 1
          from pg_constraint con
          join pg_class c on c.oid = con.conrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'limits'
            and con.conname = 'limits_rate_limits_json_object_check'
        )
        then null
        else 'Constraint limits_rate_limits_json_object_check missing'
      end as detail

    union all
    select
      'inventory.limits_flags_json_constraint' as check_name,
      case
        when exists (
          select 1
          from pg_constraint con
          join pg_class c on c.oid = con.conrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'limits'
            and con.conname = 'limits_flags_json_object_check'
        )
        then null
        else 'Constraint limits_flags_json_object_check missing'
      end as detail

    union all
    select
      'inventory.limits_set_updated_at_trigger' as check_name,
      case
        when exists (
          select 1
          from pg_trigger t
          join pg_class c on c.oid = t.tgrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'limits'
            and t.tgname = 'limits_set_updated_at'
            and not t.tgisinternal
        )
        then null
        else 'Trigger limits_set_updated_at missing'
      end as detail

    union all
    select
      'inventory.enforce_system_limit_function' as check_name,
      case
        when exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'inventory'
            and p.proname = 'enforce_system_limit'
        )
        then null
        else 'Function inventory.enforce_system_limit missing'
      end as detail

    union all
    select
      'inventory.enforce_item_limit_function' as check_name,
      case
        when exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'inventory'
            and p.proname = 'enforce_item_limit'
        )
        then null
        else 'Function inventory.enforce_item_limit missing'
      end as detail

    union all
    select
      'inventory.enforce_user_limit_function' as check_name,
      case
        when exists (
          select 1
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'inventory'
            and p.proname = 'enforce_user_limit'
        )
        then null
        else 'Function inventory.enforce_user_limit missing'
      end as detail

    union all
    select
      'inventory.enforce_system_limit_trigger' as check_name,
      case
        when exists (
          select 1
          from pg_trigger t
          join pg_class c on c.oid = t.tgrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'system'
            and t.tgname = 'system_enforce_limit'
            and not t.tgisinternal
        )
        then null
        else 'Trigger system_enforce_limit missing'
      end as detail

    union all
    select
      'inventory.enforce_item_limit_trigger' as check_name,
      case
        when exists (
          select 1
          from pg_trigger t
          join pg_class c on c.oid = t.tgrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'item'
            and t.tgname = 'item_enforce_limit'
            and not t.tgisinternal
        )
        then null
        else 'Trigger item_enforce_limit missing'
      end as detail

    union all
    select
      'inventory.enforce_user_limit_trigger' as check_name,
      case
        when exists (
          select 1
          from pg_trigger t
          join pg_class c on c.oid = t.tgrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'system_user_assignment'
            and t.tgname = 'system_user_assignment_enforce_limit'
            and not t.tgisinternal
        )
        then null
        else 'Trigger system_user_assignment_enforce_limit missing'
      end as detail

    union all
    select
      'inventory.item_template_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_template'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.item_template'
      end as detail

    union all
    select
      'inventory.item_template_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_template'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.item_template'
      end as detail

    union all
    select
      'inventory.item_template_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_template'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.item_template'
      end as detail

    union all
    select
      'inventory.item_template_field_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_template_field'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.item_template_field'
      end as detail

    union all
    select
      'inventory.item_template_field_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_template_field'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.item_template_field'
      end as detail

    union all
    select
      'inventory.item_template_field_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_template_field'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.item_template_field'
      end as detail

    union all
    select
      'inventory.item_property_definition_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_property_definition'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.item_property_definition'
      end as detail

    union all
    select
      'inventory.item_property_definition_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_property_definition'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.item_property_definition'
      end as detail

    union all
    select
      'inventory.item_property_definition_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_property_definition'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.item_property_definition'
      end as detail

    union all
    select
      'inventory.item_property_value_created_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_property_value'
            and col.column_name = 'created_by'
        )
        then null
        else 'Column created_by missing on inventory.item_property_value'
      end as detail

    union all
    select
      'inventory.item_property_value_updated_by_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_property_value'
            and col.column_name = 'updated_by'
        )
        then null
        else 'Column updated_by missing on inventory.item_property_value'
      end as detail

    union all
    select
      'inventory.item_property_value_is_active_column' as check_name,
      case
        when exists (
          select 1
          from information_schema.columns col
          where col.table_schema = 'inventory'
            and col.table_name = 'item_property_value'
            and col.column_name = 'is_active'
        )
        then null
        else 'Column is_active missing on inventory.item_property_value'
      end as detail

    union all
    select
      'inventory.system_tenant_fk' as check_name,
      case
        when exists (
          select 1
          from pg_constraint con
          join pg_class c on c.oid = con.conrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'system'
            and con.conname = 'system_tenant_fk'
        )
        then null
        else 'Foreign key system_tenant_fk missing'
      end as detail

    union all
    select
      'inventory.item_system_fk' as check_name,
      case
        when exists (
          select 1
          from pg_constraint con
          join pg_class c on c.oid = con.conrelid
          join pg_namespace n on n.oid = c.relnamespace
          where n.nspname = 'inventory'
            and c.relname = 'item'
            and con.conname = 'item_system_fk'
        )
        then null
        else 'Foreign key item_system_fk missing'
      end as detail
  )
  select check_name, detail
  from checks
  where detail is not null;
$$;
