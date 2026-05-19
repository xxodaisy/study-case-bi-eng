with orders_enriched as (
    select * from {{ ref('int_orders_enriched') }}
),

customer_stats as (
    select
        customer_id,
        count(distinct order_id) as total_orders,
        max(ordered_at) as last_order_date
    from orders_enriched
    where status = 'delivered'
     and ordered_at is not null
     and price is not null
    group by customer_id
),

segments as (
    select
        customer_id,
        total_orders,
        last_order_date,
        case
            when total_orders = 1 and last_order_date >= CURRENT_DATE - interval '180 days' then 'new'
            when total_orders > 1 then 'returning'
            when total_orders = 1 and last_order_date < CURRENT_DATE - interval '180 days' then 'churned'
            else 'unknown'
        end as customer_segment
    from customer_stats
)

select * from segments