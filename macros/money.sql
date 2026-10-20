{# Round a money expression to cents, treating nulls as zero. #}
{% macro money(expr) -%}
    round(coalesce({{ expr }}, 0)::numeric, 2)
{%- endmacro %}

{# Safe ratio: returns null instead of dividing by zero. #}
{% macro safe_ratio(numerator, denominator, precision=4) -%}
    round(({{ numerator }})::numeric / nullif(({{ denominator }})::numeric, 0), {{ precision }})
{%- endmacro %}
