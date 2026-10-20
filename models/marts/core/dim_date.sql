-- Calendar spine from the first item received through today, so time series
-- show empty days/months instead of skipping them.

with bounds as (

    select
        coalesce(min(received_date), current_date) as start_date,
        current_date                               as end_date
    from {{ ref('stg_mercantile__items') }}

),

spine as (

    select generate_series(start_date, end_date, interval '1 day')::date as date_day
    from bounds

)

select
    date_day,
    date_trunc('week', date_day)::date                   as week_start,
    date_trunc('month', date_day)::date                  as month_start,
    date_trunc('quarter', date_day)::date                as quarter_start,
    extract(year from date_day)::int                     as year,
    extract(month from date_day)::int                    as month,
    to_char(date_day, 'Mon YYYY')                        as month_label,
    extract(isodow from date_day)::int                   as day_of_week,
    to_char(date_day, 'Dy')                              as day_name,
    extract(isodow from date_day) in (6, 7)              as is_weekend
from spine
