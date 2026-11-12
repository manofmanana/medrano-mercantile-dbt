-- Hours worked on the business, by day, haul and activity.
--
-- From the first day anything is logged in public.labor_log, only logged
-- hours count. Before that, hours are estimated from what the business did
-- (items listed, buyers met, hauls picked up) using the est_hours_* vars, so
-- the year has a rough labor number even though nobody tracked time.

with items as (

    select * from {{ ref('dim_items') }}

),

logs as (

    select * from {{ ref('stg_mercantile__labor_log') }}

),

first_log as (

    select min(work_date) as first_log_date from logs

),

estimated as (

    -- listing work: one block per item, on the day it was listed
    select
        coalesce(listed_date, received_date)                     as work_date,
        haul,
        'Photos & listing'                                       as activity,
        count(*) * {{ var('est_hours_per_listing') }}            as hours
    from items
    where coalesce(listed_date, received_date) is not null
    group by 1, 2

    union all

    -- selling work: one meetup per buyer per day; when the buyer wasn't
    -- recorded, each item counts as its own sale
    select
        sold_date,
        haul,
        'Messages & meetups',
        count(distinct coalesce(buyer, sku)) * {{ var('est_hours_per_sale') }}
    from items
    where is_sold
    group by 1, 2

    union all

    -- one pickup trip per tagged haul, on the day its first item came in
    select
        min(received_date),
        haul,
        'Sourcing / pickup',
        {{ var('est_hours_per_haul_pickup') }}
    from items
    where haul is not null and received_date is not null
    group by haul

),

combined as (

    select e.work_date, e.haul, e.activity, e.hours, 'estimated' as basis
    from estimated e
    cross join first_log f
    where f.first_log_date is null or e.work_date < f.first_log_date

    union all

    select work_date, haul, activity, hours, 'logged'
    from logs

)

select
    work_date,
    date_trunc('month', work_date)::date                         as work_month,
    haul,
    activity,
    basis,
    round(sum(hours), 2)                                         as hours
from combined
group by 1, 2, 3, 4, 5
