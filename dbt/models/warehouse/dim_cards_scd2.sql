{{ config(materialized='table') }}

select
    card_id,
    customer_id,
    card_number,
    status,
    credit_limit,
    available_limit,
    dbt_valid_from as valid_from,
    dbt_valid_to as valid_to,
    dbt_valid_to is null as is_current
from {{ ref('cards_snapshot') }}
