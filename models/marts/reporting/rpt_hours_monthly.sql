-- One row per month: hours worked (logged or estimated), revenue, profit and
-- profit per hour. The number that says what the business pays for your time.

with months as (

    select distinct month_start, month_label
    from {{ ref('dim_date') }}
    where month_start <= date_trunc('month', current_date)::date

),

hours as (

    select
        work_month,
        sum(hours) filter (where basis = 'logged')               as logged_hours,
        sum(hours) filter (where basis = 'estimated')            as estimated_hours
    from {{ ref('fct_labor_hours') }}
    group by 1

),

sales as (

    select
        sold_month,
        sum(sale_price)                                          as revenue,
        sum(net_profit)                                          as net_profit
    from {{ ref('fct_sales') }}
    group by 1

),

joined as (

    select
        m.month_start,
        m.month_label,
        coalesce(h.logged_hours, 0)                              as logged_hours,
        coalesce(h.estimated_hours, 0)                           as estimated_hours,
        coalesce(h.logged_hours, 0) + coalesce(h.estimated_hours, 0) as total_hours,
        {{ money('s.revenue') }}                                 as revenue,
        {{ money('s.net_profit') }}                              as net_profit
    from months m
    left join hours h on h.work_month = m.month_start
    left join sales s on s.sold_month = m.month_start

)

select
    *,
    case
        when logged_hours > 0 and estimated_hours > 0 then 'mixed'
        when logged_hours > 0 then 'logged'
        when estimated_hours > 0 then 'estimated'
        else 'none'
    end                                                          as hours_basis,
    {{ safe_ratio('net_profit', 'total_hours', 2) }}             as profit_per_hour
from joined
