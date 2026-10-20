-- One row per item still on hand (not sold), with aging and the profit it
-- would make if it sold at the asking price.

with items as (

    select * from {{ ref('dim_items') }}
    where not is_sold

)

select
    sku,
    item_name,
    category,
    status,
    source_type,
    consignor,
    is_consignment,
    platform,
    received_date,
    listed_date,
    days_in_inventory,
    days_listed,

    case
        when days_in_inventory <= 30 then '0–30 days'
        when days_in_inventory <= 60 then '31–60 days'
        when days_in_inventory <= 90 then '61–90 days'
        else '90+ days'
    end                                                       as aging_bucket,
    case
        when days_in_inventory <= 30 then 1
        when days_in_inventory <= 60 then 2
        when days_in_inventory <= 90 then 3
        else 4
    end                                                       as aging_bucket_order,
    days_in_inventory > {{ var('stale_inventory_days') }}     as is_stale,

    acquisition_cost,
    asking_price,
    round(coalesce(asking_price, 0)
          - coalesce(asking_price * consignor_split, 0)
          - acquisition_cost, 2)                              as potential_profit
from items
