-- One row per calendar month (including months with no sales), with running
-- totals and month-over-month change.

with months as (

    select distinct month_start, month_label
    from {{ ref('dim_date') }}

),

sales as (

    select
        sold_month                         as month_start,
        count(*)                           as items_sold,
        sum(sale_price)                    as revenue,
        sum(net_profit)                    as net_profit,
        sum(consignor_payout)              as consignor_payouts,
        sum(fees_costs)                    as fees,
        avg(sale_price)                    as avg_sale_price,
        avg(days_to_sell_from_listed)      as avg_days_to_sell
    from {{ ref('fct_sales') }}
    group by 1

),

received as (

    select
        date_trunc('month', received_date)::date as month_start,
        count(*)                                 as items_received
    from {{ ref('dim_items') }}
    group by 1

),

joined as (

    select
        m.month_start,
        m.month_label,
        coalesce(r.items_received, 0)             as items_received,
        coalesce(s.items_sold, 0)                 as items_sold,
        round(coalesce(s.revenue, 0), 2)          as revenue,
        round(coalesce(s.net_profit, 0), 2)       as net_profit,
        round(coalesce(s.consignor_payouts, 0), 2) as consignor_payouts,
        round(coalesce(s.fees, 0), 2)             as fees,
        round(s.avg_sale_price, 2)                as avg_sale_price,
        round(s.avg_days_to_sell, 1)              as avg_days_to_sell
    from months m
    left join sales s using (month_start)
    left join received r using (month_start)

)

select
    *,
    {{ safe_ratio('net_profit', 'revenue') }}                                     as profit_margin,
    sum(revenue) over (order by month_start)                                      as cumulative_revenue,
    sum(net_profit) over (order by month_start)                                   as cumulative_profit,
    {{ safe_ratio('revenue - lag(revenue) over (order by month_start)',
                  'lag(revenue) over (order by month_start)') }}                  as revenue_mom_change_pct
from joined
