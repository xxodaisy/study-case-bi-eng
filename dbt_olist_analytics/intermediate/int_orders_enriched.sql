with orders as(
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

order_reviews as(
    select * from {{ ref('stg_order_reviews') }}
),

joined as(
    SELECT
        o.order_id,
        o.customer_id,
        o.status,
        o.ordered_at,
        o.approved_at,
        o.delivered_at,
        o.estimated_delivery_at,

        c.city,
        c.state,

        oi.seller_id,
        oi.price,
        oi.freight_value,

        r.rating,
        r.reviewed_at,

        EXTRACT(DAY FROM(o.delivered_at - o.estimated_delivery_at)) as delivery_delay_days,

        CASE
            WHEN EXTRACT(DAY FROM (o.delivered_at - o.estimated_delivery_at)) >0
            THEN true
            ELSE false
        END as is_late_delivery
    FROM orders o  
    left join customers c on o.customer_id = c.customer_id
    left join order_items oi on o.order_id = oi.order_id
    left join order_reviews r on o.order_id = r.order_id
)

select * from joined