{{ config(materialized='table') }}

select
    customer_id,
    full_name,
    email,
    phone,
    address,
    city,
    state_code,
    dbt_valid_from as valid_from,
    dbt_valid_to as valid_to,
    dbt_valid_to is null as is_current
from {{ ref('customers_snapshot') }}
