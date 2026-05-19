with orders_enriched as (
    select * from {{ ref('int_orders_enriched') }}
),

monthly_revenue as (
    select
        date_trunc('month', ordered_at) as month,
        sum(price) as total_revenue,
        count(distinct order_id) as total_orders
    from orders_enriched
    where status = 'delivered'
     and ordered_at is not null
     and price is not null
    group by month
),

with_growth as (
    select
        month,
        total_revenue,
        total_orders,
        lag(total_revenue) over (order by month) as prev_month_revenue,
        round((total_revenue - lag(total_revenue) over (order by month)) / lag(total_revenue) over (order by month) * 100, 2) as revenue_growth_rate
    from monthly_revenue
)

select * from with_growth
order by month