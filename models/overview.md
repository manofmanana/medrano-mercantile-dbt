{% docs __overview__ %}
# Medrano Mercantile — analytics

This dbt project turns the raw inventory ledger (`public.items` in the
`mercantile` Postgres database) into clean, tested tables for the Metabase
dashboard.

| Layer | Schema | What's in it |
|---|---|---|
| Staging | `staging` | `stg_mercantile__items` — typed, trimmed, normalized copy of the source |
| Core marts | `marts` | `dim_date`, `dim_items`, `fct_sales`, `fct_inventory` |
| Reporting | `marts` | `rpt_*` tables shaped one-to-one for dashboard cards |

**Net profit** = sale price − consignor payout − fees − acquisition cost.

Rebuilt every 15 minutes by `dbt-nightly.timer` on Data-Lab (VM 110).
Source: [github.com/manofmanana/medrano-mercantile-dbt](https://github.com/manofmanana/medrano-mercantile-dbt).
{% enddocs %}
