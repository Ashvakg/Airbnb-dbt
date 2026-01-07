{{ config(materialized='incremental') }}

{% set incremental_col = 'created_at' %}

select *
from {{ source('staging', 'listings') }}
{% if is_incremental() %}
where {{ incremental_col }} >
  (select coalesce(max({{ incremental_col }}), '1900-01-01'::timestamp)
   from {{ this }})
{% endif %}