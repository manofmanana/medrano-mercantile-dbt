-- Single-row headline numbers for the dashboard's KPI tiles, including
-- trailing-30-day vs prior-30-day comparisons.

with sales as (

    select * from {{ ref('fct_sales') }}

),

inventory as (

    select * from {{ ref('fct_inventory') }}

),

sales_totals as (

    select
        count(*)                                                        as items_sold,
        sum(sale_price)                                                 as total_revenue,
        sum(net_profit)                                                 as total_profit,
        avg(sale_price)                                                 as avg_sale_price,
        avg(days_to_sell_from_listed)                                   as avg_days_to_sell,
        sum(consignor_payout)                                           as total_consignor_payouts,

        count(*) filter (where sold_date > current_date - 30)           as items_sold_30d,
        coalesce(sum(sale_price) filter (where sold_date > current_date - 30), 0) as revenue_30d,
        coalesce(sum(net_profit) filter (where sold_date > current_date - 30), 0) as profit_30d,
        coalesce(sum(sale_price) filter (
            where sold_date >  current_date - 60
              and sold_date <= current_date - 30), 0)                   as revenue_prev_30d,
        coalesce(sum(net_profit) filter (
            where sold_date >  current_date - 60
              and sold_date <= current_date - 30), 0)                   as profit_prev_30d
    from sales

),

inventory_totals as (

    select
        count(*)                                                        as open_items,
        coalesce(sum(asking_price), 0)                                  as open_inventory_value,
        coalesce(sum(potential_profit), 0)                              as open_potential_profit,
        count(*) filter (where is_stale)                                as stale_items,
        avg(days_in_inventory)                                          as avg_days_on_hand
    from inventory

)

select
    s.items_sold,
    round(s.total_revenue, 2)                                           as total_revenue,
    round(s.total_profit, 2)                                            as total_profit,
    {{ safe_ratio('s.total_profit', 's.total_revenue') }}               as profit_margin,
    round(s.avg_sale_price, 2)                                          as avg_sale_price,
    round(s.avg_days_to_sell, 1)                                        as avg_days_to_sell,
    round(s.total_consignor_payouts, 2)                                 as total_consignor_payouts,

    s.items_sold_30d,
    round(s.revenue_30d, 2)                                             as revenue_30d,
    round(s.revenue_prev_30d, 2)                                        as revenue_prev_30d,
    {{ safe_ratio('s.revenue_30d - s.revenue_prev_30d', 's.revenue_prev_30d') }} as revenue_30d_change_pct,
    round(s.profit_30d, 2)                                              as profit_30d,
    round(s.profit_prev_30d, 2)                                         as profit_prev_30d,

    i.open_items,
    round(i.open_inventory_value, 2)                                    as open_inventory_value,
    round(i.open_potential_profit, 2)                                   as open_potential_profit,
    i.stale_items,
    round(i.avg_days_on_hand, 1)                                        as avg_days_on_hand,
    {{ safe_ratio('s.items_sold', 's.items_sold + i.open_items') }}     as sell_through_rate,

    current_timestamp                                                   as refreshed_at
from sales_totals s
cross join inventory_totals i
