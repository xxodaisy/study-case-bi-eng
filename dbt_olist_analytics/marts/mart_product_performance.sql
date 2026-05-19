with products as (
    select * from {{ ref('stg_products') }}
),

order_items as(
    select * from {{ ref('stg_order_items') }}
),

order_reviews as(
    select * from {{ ref('stg_order_reviews') }}
),

joined as (
    SELECT
        p.product_id,
        p.product_category_name,
        p.category_name_english,
        sum(oi.price) as total_revenue,
        count(*) as units_sold,
        avg(r.rating) as avg_review_score
    FROM order_items oi
    left join products p on oi.product_id = p.product_id
    left join order_reviews r on oi.order_id = r.order_id
    group by 1,2,3
),

ranked as (
    select
        *,
        rank() over(order by total_revenue desc) as revenue_rank,
        rank() over(order by units_sold desc) as units_sold_rank,
        rank() over(order by avg_review_score desc) as review_score_rank
    from joined
)

select * from ranked
order by total_revenue desc