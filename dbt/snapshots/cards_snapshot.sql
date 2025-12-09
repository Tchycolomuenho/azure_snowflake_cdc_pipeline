{% snapshot cards_snapshot %}
{{
  config(
    target_schema='SNAPSHOTS',
    target_database='ANALYTICS',
    unique_key='card_id',
    strategy='timestamp',
    updated_at='landed_at',
    invalidate_hard_deletes=True
  )
}}

select
  card_id,
  customer_id,
  card_number,
  status,
  credit_limit,
  available_limit,
  landed_at
from {{ source('raw', 'cards') }}
{% endsnapshot %}
