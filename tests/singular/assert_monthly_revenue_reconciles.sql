-- Monthly report must add up to the same total as the sales fact table.

with monthly as (
    select sum(revenue) as revenue from {{ ref('rpt_sales_monthly') }}
),

facts as (
    select coalesce(sum(sale_price), 0) as revenue from {{ ref('fct_sales') }}
)

select monthly.revenue as monthly_revenue, facts.revenue as fact_revenue
from monthly cross join facts
where abs(monthly.revenue - facts.revenue) > 0.01
