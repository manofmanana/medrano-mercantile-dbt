-- One row per haul (sourcing event): what came in, what sold, what it earned,
-- the hours it took and profit per hour. Untagged items roll up to "(no haul)".

with items as (

    select coalesce(haul, '(no haul)') as haul_name, *
    from {{ ref('dim_items') }}

),

hours as (

    select
        coalesce(haul, '(no haul)')                              as haul_name,
        sum(hours) filter (where basis = 'logged')               as logged_hours,
        sum(hours) filter (where basis = 'estimated')            as estimated_hours
    from {{ ref('fct_labor_hours') }}
    group by 1

),

item_totals as (

    select
        haul_name,
        min(received_date)                                       as first_received_date,
        count(*)                                                 as items,
        count(*) filter (where is_sold)                          as items_sold,
        count(*) filter (where not is_sold)                      as items_open,
        sum(sale_price) filter (where is_sold)                   as revenue,
        sum(net_profit) filter (where is_sold)                   as net_profit,
        sum(asking_price) filter (where not is_sold)             as open_asking_value,
        avg(days_listed) filter (where is_sold)                  as avg_days_to_sell
    from items
    group by 1

)

select
    coalesce(i.haul_name, h.haul_name)                           as haul,
    i.first_received_date,
    coalesce(i.items, 0)                                         as items,
    coalesce(i.items_sold, 0)                                    as items_sold,
    coalesce(i.items_open, 0)                                    as items_open,
    {{ money('i.revenue') }}                                     as revenue,
    {{ money('i.net_profit') }}                                  as net_profit,
    {{ money('i.open_asking_value') }}                           as open_asking_value,
    {{ safe_ratio('i.items_sold', 'i.items') }}                  as sell_through_rate,
    round(i.avg_days_to_sell, 1)                                 as avg_days_to_sell,
    coalesce(h.logged_hours, 0)                                  as logged_hours,
    coalesce(h.estimated_hours, 0)                               as estimated_hours,
    coalesce(h.logged_hours, 0) + coalesce(h.estimated_hours, 0) as total_hours,
    {{ safe_ratio('i.net_profit', 'coalesce(h.logged_hours, 0) + coalesce(h.estimated_hours, 0)', 2) }} as profit_per_hour
from item_totals i
full outer join hours h on h.haul_name = i.haul_name
