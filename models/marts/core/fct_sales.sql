-- One row per sold item. The grain Metabase uses for revenue and profit.

with items as (

    select * from {{ ref('dim_items') }}
    where is_sold

)

select
    sku,
    item_name,
    sold_date,
    date_trunc('month', sold_date)::date                      as sold_month,
    received_date,
    listed_date,

    category,
    platform,
    source_type,
    consignor,
    is_consignment,

    sale_price,
    asking_price,
    acquisition_cost,
    fees_costs,
    consignor_payout,
    net_profit,
    sale_price - consignor_payout                             as house_revenue,
    {{ safe_ratio('net_profit', 'sale_price') }}              as profit_margin,
    asking_price - sale_price                                 as discount_amount,
    {{ safe_ratio('asking_price - sale_price', 'asking_price') }} as discount_pct,

    days_in_inventory                                         as days_to_sell_from_received,
    days_listed                                               as days_to_sell_from_listed
from items
