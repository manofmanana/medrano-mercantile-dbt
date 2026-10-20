-- One row per consignor (excluding the business itself): items placed,
-- sold, and what the consignor is owed.

with items as (

    select * from {{ ref('dim_items') }}
    where is_consignment

)

select
    consignor,
    max(consignor_split)                                            as consignor_split,
    count(*)                                                        as items_placed,
    count(*) filter (where is_sold)                                 as items_sold,
    count(*) filter (where not is_sold)                             as items_open,
    round(coalesce(sum(sale_price) filter (where is_sold), 0), 2)   as gross_sales,
    round(coalesce(sum(consignor_payout), 0), 2)                    as payout_owed,
    round(coalesce(sum(net_profit), 0), 2)                          as house_profit,
    max(sold_date)                                                  as last_sale_date
from items
group by consignor
