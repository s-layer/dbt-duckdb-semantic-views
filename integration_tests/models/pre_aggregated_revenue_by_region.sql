{{ config(materialized='table') }}

-- The pre-aggregated table sem_orders_materializations routes region-grain queries to.
-- Its total is the raw sum plus 1000 per region, so a test can tell which source answered.
select region_id, sum(amount) + 1000 as total_amount
from {{ ref('raw_orders') }}
group by region_id
