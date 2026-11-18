-- sem_orders_switch was a plain view (or, in a later CI step, a table) before it became a
-- semantic view. Standard SQL against it must reach the semantic view, not the old relation,
-- which CI creates first and which would otherwise answer with its stale total of 999.00 for
-- region 1.
with results as (
  select region_id, agg(total_amount) as total_amount
  from {{ ref('sem_orders_switch') }}
  group by region_id
),
expected as (
  select 1 as region_id, 690.00::decimal(10,2) as total_amount
  union all
  select 2 as region_id, 800.00::decimal(10,2) as total_amount
)

select 'mismatch' as failure_reason, coalesce(e.region_id, r.region_id) as region_id, e.total_amount as expected_total, r.total_amount as actual_total
from expected e
full outer join results r on r.region_id = e.region_id
where e.region_id is null or r.region_id is null
  or r.total_amount is distinct from e.total_amount
