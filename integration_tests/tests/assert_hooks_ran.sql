-- The pre-hook built hook_source (region 2 only) before the semantic view bound it, and the
-- post-hook queried the finished view into hook_post. Any rows returned == failure.
-- depends_on: {{ ref('sem_orders_hooks') }}

with expected as (
  select 2 as region_id, 800.00::decimal(10,2) as total_amount
)

select 'mismatch' as failure_reason, coalesce(e.region_id, r.region_id) as region_id,
  e.total_amount as expected_total, r.total_amount as actual_total
from expected e
full outer join {{ target.schema }}.hook_post r on r.region_id = e.region_id
where e.region_id is null or r.region_id is null or r.total_amount is distinct from e.total_amount
