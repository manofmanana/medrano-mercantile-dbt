-- One row per block of time worked on the business, as logged from Metabase.

with source as (

    select * from {{ source('mercantile', 'labor_log') }}

)

select
    entry_id,
    work_date,
    hours::numeric(5, 2)                                        as hours,
    nullif(btrim(haul), '')                                     as haul,
    coalesce(nullif(btrim(activity), ''), 'General')            as activity,
    nullif(btrim(notes), '')                                    as notes,
    created_at
from source
