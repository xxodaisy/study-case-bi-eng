with base_items as (
	select
		oi.order_id,
		oi.product_id,
		oi.price,
		p.product_category_name,
		t.product_category_name_english as category
	from order_items oi 
	join products p on oi.product_id = p.product_id 
	left join product_category_name_translation t on p.product_category_name = t.product_category_name 
),

category_revenue as (
	select 
		category,
		count(distinct order_id) as total_orders,
		count(*) as total_items,
		round(sum(price)::numeric,2) as total_revenue
	from base_items
	group by category
),

payment_per_order as (
	select
		order_id,
		round(coalesce(sum(payment_value) filter (where payment_type = 'credit_card'),0)::numeric,2) as credit_card_revenue,
		round(coalesce(sum(payment_value) filter (where payment_type = 'boleto'),0)::numeric,2) as boleto_revenue
	from order_payments
	group by order_id
), 

payment_by_category as (
	select
		b.category,
		sum(p.credit_card_revenue) as credit_card_revenue,
		sum(p.boleto_revenue) as boleto_revenue
	from base_items b
	join payment_per_order p on b.order_id = p.order_id
	group by b.category
),

late_ships as (
	select
		b.category,
		count(distinct case 
			when o.order_delivered_customer_date > o.order_estimated_delivery_date 
			then o.order_id 
		end
			) as late_count,
		round(avg(case
			when o.order_delivered_customer_date > o.order_estimated_delivery_date
			then extract(epoch from(o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400
		end
		)::numeric, 1) as avg_days_late
	from base_items b
	join orders o on b.order_id = o.order_id 
	where o.order_delivered_customer_date is not null 
	group by b.category
),

ranked_revenue as ( 
	select 
		rank() over(order by cr.total_revenue desc) as revenue_rank,
		cr. category,
		cr.total_orders,
		cr.total_revenue,
		round((cr.total_revenue *100.0 / nullif(sum(total_revenue) over(), 0))::numeric,2) as revenue_share_pct,
		round((sum(total_revenue) over (order by cr.total_revenue desc rows between unbounded preceding and current row) * 100.0
		/ nullif (sum(cr.total_revenue) over(), 0))::numeric, 2) as cumulative_revenue_pct,
		round((cr.total_revenue / nullif(cr.total_orders, 0))::numeric, 2) as avg_order_value,
		pbc.credit_card_revenue,
		pbc.boleto_revenue,
		round((pbc.credit_card_revenue * 100.0 /
		nullif(pbc.credit_card_revenue + pbc.boleto_revenue, 0))::numeric,1) as credit_card_share_pct,
		ls.late_count,
		ls.avg_days_late,
		round((ls.late_count *100.0 / nullif (cr.total_orders, 0))::numeric,1) as late_rate_pct
	from category_revenue cr
	left join payment_by_category pbc on cr.category = pbc.category
	left join late_ships ls on cr.category = ls.category
)

select 
	revenue_rank,
	category,
	total_orders,
	total_revenue,
	revenue_share_pct,
	cumulative_revenue_pct,
	avg_order_value,
	credit_card_revenue,
	boleto_revenue,
	credit_card_share_pct,
	late_count,
	late_rate_pct,
	avg_days_late,
	rank() over(order by late_rate_pct desc) as late_rank
from ranked_revenue
where category is not null
order by revenue_rank;