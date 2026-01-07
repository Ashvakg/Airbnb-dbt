{{ 
    config(
        materialized='incremental',
        unique_key='booking_id'
    )
}}

select
    booking_id,
    listing_id,
    booking_date,
    nights_booked,
    booking_amount,
    cleaning_fee,
    service_fee,
     + cleaning_fee + service_fee as total_booking_amount,
    booking_status,
    created_at
from {{ ref('bronze_bookings') }}