{{ config(materialized='incremental', unique_key='card_id', incremental_strategy='merge', on_schema_change='sync_all_columns') }}

with src as (
    select
        card_id,
        customer_id,
        card_number,
        status,
        credit_limit,
        available_limit,
        landed_at,
        _file,
        _row
    from {{ source('raw', 'cards') }}
    {% if is_incremental() %}
    where landed_at > (select coalesce(max(landed_at), '1900-01-01'::timestamp) from {{ this }})
    {% endif %}
)

select * from src
