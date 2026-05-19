with orders_enriched as (
    select * from {{ ref('int_orders_enriched') }}
),

seller_metrics as (
    select
        seller_id,
        count(distinct order_id) as total_orders,
        sum(price) as total_revenue,
        avg(rating) as avg_review_score,
        avg(case when is_late_delivery then 1 else 0 end) as late_delivery_rate
    from orders_enriched
    group by seller_id
)

select * from seller_metrics