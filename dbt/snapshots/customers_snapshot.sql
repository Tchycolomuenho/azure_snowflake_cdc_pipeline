{% snapshot customers_snapshot %}
{{
  config(
    target_schema='SNAPSHOTS',
    target_database='ANALYTICS',
    unique_key='customer_id',
    strategy='timestamp',
    updated_at='landed_at',
    invalidate_hard_deletes=True
  )
}}

select
  customer_id,
  full_name,
  email,
  phone,
  address,
  city,
  state_code,
  landed_at
from {{ source('raw', 'customers') }}
{% endsnapshot %}
