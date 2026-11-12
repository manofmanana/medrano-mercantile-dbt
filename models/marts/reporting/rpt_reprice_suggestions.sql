-- One row per listed item with what to do about its price this week.
--
-- Rules, first match wins:
--   1. On hand clear_out_after_days or more   -> Clear out (wholesale buyer, bundle or donate)
--   2. Asking below bundle_below_price        -> Bundle
--   3. Same price for reprice_after_days_at_price days -> Drop price by reprice_drop_pct,
--      rounded down to the nearest $5
--   4. Otherwise                              -> Hold
--
-- "Same price since" comes from the snap_items history. Before the snapshot
-- has seen a change, the listing date is used.

with inventory as (

    select * from {{ ref('fct_inventory') }}
    where status = 'Listed'

),

history as (

    select
        sku,
        asking_price,
        dbt_valid_from,
        lag(asking_price) over (partition by sku order by dbt_valid_from) as previous_price,
        row_number() over (partition by sku order by dbt_valid_from)      as version
    from {{ ref('snap_items') }}

),

price_changes as (

    select
        sku,
        max(dbt_valid_from)::date                                as last_price_change_date,
        count(*)                                                 as price_changes
    from history
    where version > 1 and asking_price is distinct from previous_price
    group by sku

),

priced as (

    select
        i.sku,
        i.item_name,
        i.category,
        i.received_date,
        i.listed_date,
        i.days_in_inventory,
        i.asking_price,
        coalesce(c.price_changes, 0)                             as price_changes,
        greatest(coalesce(i.listed_date, i.received_date), c.last_price_change_date) as price_since,
        floor(i.asking_price * (1 - {{ var('reprice_drop_pct') }}) / 5) * 5 as dropped_price
    from inventory i
    left join price_changes c using (sku)

),

ruled as (

    select
        *,
        current_date - price_since                               as days_at_price,
        case
            when days_in_inventory >= {{ var('clear_out_after_days') }} then 'Clear out'
            when asking_price < {{ var('bundle_below_price') }} then 'Bundle'
            when current_date - price_since >= {{ var('reprice_after_days_at_price') }}
                 and dropped_price > 0 and dropped_price < asking_price then 'Drop price'
            else 'Hold'
        end                                                      as action
    from priced

)

select
    sku,
    item_name,
    category,
    received_date,
    listed_date,
    days_in_inventory,
    asking_price,
    price_since,
    days_at_price,
    price_changes,
    action,
    case action
        when 'Clear out' then 1
        when 'Drop price' then 2
        when 'Bundle' then 3
        else 4
    end                                                          as action_order,
    case when action = 'Drop price' then dropped_price end       as suggested_price,
    case action
        when 'Clear out' then 'On hand ' || days_in_inventory || ' days: offer it to the wholesale buyer, bundle it, or donate it'
        when 'Bundle' then 'Under $' || {{ var('bundle_below_price') }} || ': sell it in a bundle or lot'
        when 'Drop price' then 'No sale in ' || days_at_price || ' days at $' || asking_price::int || ': drop to $' || dropped_price::int
        else 'Price set ' || coalesce(days_at_price::text, '?') || ' days ago'
    end                                                          as reason
from ruled
