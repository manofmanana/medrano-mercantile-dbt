-- Every sale belongs to exactly one haul row, so haul revenue must add up to
-- total revenue.

select h.total, s.total
from (select sum(revenue) as total from {{ ref('rpt_haul_performance') }}) h
cross join (select coalesce(sum(sale_price), 0) as total from {{ ref('fct_sales') }}) s
where h.total <> s.total
