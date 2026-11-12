-- A suggested price must be below the current asking price.

select sku, asking_price, suggested_price
from {{ ref('rpt_reprice_suggestions') }}
where suggested_price is not null
  and suggested_price >= asking_price
