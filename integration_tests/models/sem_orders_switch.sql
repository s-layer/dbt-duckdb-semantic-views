{#-
  A model that was a plain view or table and is now a semantic view. CI first builds it with
  `--vars '{sem_orders_switch_as: view}'` (and later `table`), then as a semantic view: the
  old relation must not survive to shadow the semantic view in standard SQL (see
  assert_switched_from_view). A plain `dbt build` has no old relation to replace, so only
  those CI steps exercise the switch.
-#}
{% set was = var('sem_orders_switch_as', 'semantic_view') %}
{% if was in ('view', 'table') %}
{{ config(materialized=was) }}
-- What the model used to be: a plain view or table with a stale, wrong total.
select 1 as region_id, 999.00::decimal(10,2) as total_amount
{% else %}
{{ config(materialized='semantic_view') }}
TABLES (
  orders AS {{ ref('raw_orders') }} PRIMARY KEY (order_id)
)
DIMENSIONS (
  orders.region_id AS region_id
)
METRICS (
  orders.total_amount AS sum(amount)
)
{% endif %}
