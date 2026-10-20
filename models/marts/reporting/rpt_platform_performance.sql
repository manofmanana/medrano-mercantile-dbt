-- One row per sales platform (Facebook Marketplace, Depop, ...).

select
    platform,
    count(*)                                        as items_sold,
    round(sum(sale_price), 2)                       as revenue,
    round(sum(net_profit), 2)                       as net_profit,
    {{ safe_ratio('sum(net_profit)', 'sum(sale_price)') }} as profit_margin,
    round(avg(sale_price), 2)                       as avg_sale_price,
    round(avg(days_to_sell_from_listed), 1)         as avg_days_to_sell,
    round(avg(discount_pct), 4)                     as avg_discount_pct
from {{ ref('fct_sales') }}
group by platform
