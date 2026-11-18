{#-
  Hooks around a semantic view. The pre-hook creates the table the view is built on, which
  must exist before CREATE SEMANTIC VIEW binds it; the post-hook queries the new view and
  keeps the result in hook_post, which assert_hooks_ran checks.
-#}
{{ config(
    materialized='semantic_view',
    pre_hook="create or replace table {{ target.schema }}.hook_source as select * from {{ ref('raw_orders') }} where region_id = 2",
    post_hook="create or replace table {{ target.schema }}.hook_post as select * from semantic_view('{{ target.database }}.{{ target.schema }}.{{ this.identifier }}', dimensions := ['region_id'], metrics := ['total_amount'])"
) }}

TABLES (
  orders AS {{ target.schema }}.hook_source PRIMARY KEY (order_id)
)
DIMENSIONS (
  orders.region_id AS region_id
)
METRICS (
  orders.total_amount AS sum(amount)
)
