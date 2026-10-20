-- One row per category: what sold, what's still sitting, and how fast it moves.

with items as (

    select * from {{ ref('dim_items') }}

)

select
    category,
    count(*)                                                        as items_total,
    count(*) filter (where is_sold)                                 as items_sold,
    count(*) filter (where not is_sold)                             as items_open,
    round(coalesce(sum(sale_price) filter (where is_sold), 0), 2)   as revenue,
    round(coalesce(sum(net_profit), 0), 2)                          as net_profit,
    {{ safe_ratio('sum(net_profit)', 'sum(sale_price) filter (where is_sold)') }} as profit_margin,
    round(avg(sale_price) filter (where is_sold), 2)                as avg_sale_price,
    round(avg(days_listed) filter (where is_sold), 1)               as avg_days_to_sell,
    round(coalesce(sum(asking_price) filter (where not is_sold), 0), 2) as open_inventory_value,
    {{ safe_ratio('count(*) filter (where is_sold)', 'count(*)') }} as sell_through_rate
from items
group by category
