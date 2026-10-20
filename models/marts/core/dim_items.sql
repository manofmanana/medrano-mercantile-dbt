-- One row per item with its full lifecycle: where it came from, how long it
-- has been around, and (once sold) what it earned.

with items as (

    select * from {{ ref('stg_mercantile__items') }}

)

select
    sku,
    item_name,
    category,
    status,
    source_type,
    consignor,
    is_consignment,
    is_sold,
    platform,

    received_date,
    listed_date,
    sold_date,
    coalesce(sold_date, current_date) - received_date          as days_in_inventory,
    coalesce(sold_date, current_date) - listed_date            as days_listed,

    acquisition_cost,
    asking_price,
    sale_price,
    fees_costs,
    consignor_split,

    case
        when is_sold and consignor_split is not null
            then round(sale_price * consignor_split, 2)
        else 0
    end                                                        as consignor_payout,

    case
        when is_sold then round(
            sale_price
            - coalesce(sale_price * consignor_split, 0)
            - fees_costs
            - acquisition_cost, 2)
    end                                                        as net_profit,

    updated_at
from items
