{{ config(materialized='incremental', unique_key='transaction_id', incremental_strategy='merge', on_schema_change='append_new_columns') }}

with txn as (
    select * from {{ ref('stg_transactions') }}
    {% if is_incremental() %}
    where landed_at > (select coalesce(max(landed_at), '1900-01-01'::timestamp) from {{ this }})
    {% endif %}
),
card_dim as (
    select *, coalesce(valid_to, '2999-12-31'::timestamp) as valid_to_norm
    from {{ ref('dim_cards_scd2') }}
),
customer_dim as (
    select *, coalesce(valid_to, '2999-12-31'::timestamp) as valid_to_norm
    from {{ ref('dim_customers_scd2') }}
)

select
    t.transaction_id,
    t.card_id,
    c.customer_id,
    t.merchant,
    t.amount,
    t.currency,
    t.status,
    t.event_ts,
    t.landed_at,
    current_timestamp() as processed_at
from txn t
left join card_dim c on t.card_id = c.card_id and t.event_ts between c.valid_from and c.valid_to_norm
left join customer_dim cu on c.customer_id = cu.customer_id and t.event_ts between cu.valid_from and cu.valid_to_norm
