-- MATERIALIZATIONS routing: a query at the materialization's grain reads the pre-aggregated
-- table, and a query at a grain it does not cover reads the base table.
-- pre_aggregated_revenue_by_region adds 1000 per region to the raw sums, so the numbers show
-- which source answered. Per dbt singular test convention: any rows returned == failure.
-- depends_on: {{ ref('sem_orders_materializations') }}

with region_grain as (
  select region_id, total_amount
  from semantic_view(
    '{{ target.database }}.{{ target.schema }}.sem_orders_materializations',
    dimensions := ['region_id'],
    metrics := ['total_amount']
  )
),
expected_region as (
  select 1 as region_id, 1690.00::decimal(10,2) as total_amount
  union all
  select 2 as region_id, 1800.00::decimal(10,2) as total_amount
),
date_grain as (
  select order_date, total_amount
  from semantic_view(
    '{{ target.database }}.{{ target.schema }}.sem_orders_materializations',
    dimensions := ['order_date'],
    metrics := ['total_amount']
  )
),
expected_date as (
  select order_date, sum(amount) as total_amount
  from {{ ref('raw_orders') }}
  group by order_date
),
plans as (
  select 'region_id' as grain, list(explain_output) as lines
  from explain_semantic_view(
    '{{ target.database }}.{{ target.schema }}.sem_orders_materializations',
    dimensions := ['region_id'],
    metrics := ['total_amount']
  )
  union all
  select 'order_date' as grain, list(explain_output) as lines
  from explain_semantic_view(
    '{{ target.database }}.{{ target.schema }}.sem_orders_materializations',
    dimensions := ['order_date'],
    metrics := ['total_amount']
  )
)

select 'region grain mismatch' as failure_reason, coalesce(e.region_id, r.region_id)::varchar as key,
  e.total_amount as expected_total, r.total_amount as actual_total
from expected_region e
full outer join region_grain r on r.region_id = e.region_id
where e.region_id is null or r.region_id is null or r.total_amount is distinct from e.total_amount

union all

select 'date grain mismatch', coalesce(e.order_date, r.order_date)::varchar,
  e.total_amount, r.total_amount
from expected_date e
full outer join date_grain r on r.order_date = e.order_date
where e.order_date is null or r.order_date is null or r.total_amount is distinct from e.total_amount

union all

select 'wrong materialization in plan', grain, null, null
from plans
where not list_contains(
  lines,
  case grain when 'region_id' then '-- Materialization: region_agg' else '-- Materialization: none' end
)
