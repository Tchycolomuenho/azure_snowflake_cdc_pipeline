{{ config(materialized='incremental', unique_key='transaction_id', incremental_strategy='merge', on_schema_change='sync_all_columns') }}

with src as (
    select
        transaction_id,
        card_id,
        merchant,
        amount,
        currency,
        status,
        event_ts,
        landed_at,
        _file,
        _row
    from {{ source('raw', 'transactions') }}
    {% if is_incremental() %}
    where landed_at > (select coalesce(max(landed_at), '1900-01-01'::timestamp) from {{ this }})
    {% endif %}
)

select * from src
