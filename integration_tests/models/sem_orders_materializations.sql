{{ config(materialized='semantic_view') }}

TABLES (
  orders AS {{ ref('raw_orders') }} PRIMARY KEY (order_id)
)
DIMENSIONS (
  orders.region_id AS region_id,
  orders.order_date AS order_date
)
METRICS (
  orders.total_amount AS sum(amount)
)
MATERIALIZATIONS (
  region_agg AS (
    TABLE {{ ref('pre_aggregated_revenue_by_region') }},
    DIMENSIONS (region_id),
    METRICS (total_amount)
  )
)
