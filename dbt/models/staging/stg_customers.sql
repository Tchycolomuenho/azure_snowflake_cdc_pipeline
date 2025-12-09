{{ config(materialized='incremental', unique_key='customer_id', incremental_strategy='merge', on_schema_change='sync_all_columns') }}

with src as (
    select
        customer_id,
        full_name,
        email,
        phone,
        address,
        city,
        state_code,
        landed_at,
        _file,
        _row
    from {{ source('raw', 'customers') }}
    {% if is_incremental() %}
    where landed_at > (select coalesce(max(landed_at), '1900-01-01'::timestamp) from {{ this }})
    {% endif %}
)

select * from src
