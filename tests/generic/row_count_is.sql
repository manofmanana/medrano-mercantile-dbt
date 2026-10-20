{% test row_count_is(model, expected) %}
    select count(*) as row_count
    from {{ model }}
    having count(*) <> {{ expected }}
{% endtest %}
