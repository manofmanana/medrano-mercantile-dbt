-- Sold items must have a sale price and date; unsold items must have neither.

select sku, status, sale_price, sold_date
from {{ ref('stg_mercantile__items') }}
where (is_sold and (sale_price is null or sold_date is null))
   or (not is_sold and (sale_price is not null or sold_date is not null))
