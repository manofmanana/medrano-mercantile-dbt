-- An item can't be listed before it arrives or sold before it's listed/received.

select sku, received_date, listed_date, sold_date
from {{ ref('stg_mercantile__items') }}
where listed_date < received_date
   or sold_date   < received_date
   or sold_date   < listed_date
