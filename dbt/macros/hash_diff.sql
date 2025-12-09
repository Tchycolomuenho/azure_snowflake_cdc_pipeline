{% macro hash_diff(columns) %}
    md5({{ " || '|' || ".join(columns) }})
{% endmacro %}
