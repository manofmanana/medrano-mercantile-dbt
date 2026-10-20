-- One row per item. Cleans types and labels; no business logic beyond that.

with source as (

    select * from {{ source('mercantile', 'items') }}

),

renamed as (

    select
        -- keys
        btrim(sku)                                              as sku,

        -- descriptors
        btrim(item_name)                                        as item_name,
        case btrim(category)
            when 'Sporting-Goods' then 'Sports'
            when ''               then 'Uncategorized'
            else coalesce(btrim(category), 'Uncategorized')
        end                                                     as category,
        btrim(status)                                           as status,
        coalesce(nullif(btrim(source_type), ''), 'Owned Inventory') as source_type,
        coalesce(nullif(btrim(consignor), ''), 'Self')          as consignor,
        coalesce(nullif(btrim(platform), ''), 'Unknown')        as platform,
        nullif(btrim(buyer), '')                                as buyer,
        nullif(btrim(notes), '')                                as notes,

        -- money
        owner_split::numeric(5, 4)                              as consignor_split,
        coalesce(acquisition_cost, 0)::numeric(12, 2)           as acquisition_cost,
        asking_price::numeric(12, 2)                            as asking_price,
        sale_price::numeric(12, 2)                              as sale_price,
        coalesce(fees_costs, 0)::numeric(12, 2)                 as fees_costs,

        -- dates
        nullif(date_received, '')::date                         as received_date,
        nullif(date_listed, '')::date                           as listed_date,
        nullif(date_sold, '')::date                             as sold_date,
        nullif(updated_at, '')::timestamptz                     as updated_at

    from source

)

select
    *,
    source_type = 'Consignment'                                 as is_consignment,
    status = 'Sold'                                             as is_sold
from renamed
