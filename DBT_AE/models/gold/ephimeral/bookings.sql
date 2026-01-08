{{
    config(
        materialized = 'ephemeral'
    )
}}

select 
    booking_id,
    booking_date,
    booking_status,
    created_at
from {{ ref('obt') }}