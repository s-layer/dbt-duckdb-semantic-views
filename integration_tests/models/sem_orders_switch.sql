{#-
  A model that was a plain view and is now a semantic view. CI first builds it with
  `--vars '{sem_orders_switch_as: view}'`, then as a semantic view: the old view must not
  survive to shadow the semantic view in standard SQL (see assert_switched_from_view).
-#}
{% if var('sem_orders_switch_as', 'semantic_view') == 'view' %}
{{ config(materialized='view') }}
-- What the model used to be: a plain view with a stale, wrong total.
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
