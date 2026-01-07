{% set nights_booked = 1 %}
{% set booking_status = 'cancelled' %}

with cte as (
  select *
  from {{ ref('bronze_bookings') }}
)
select listing_id,count(booking_status) as Cancelled_booking_nights, sum(service_fee) as Total_service_fee
from cte
where nights_booked > {{ nights_booked }} and booking_status = '{{ booking_status }}'
group by listing_id
order by Cancelled_booking_nights desc

