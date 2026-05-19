--monthly revenue trend
with monthly_revenue as (
	select 
		date_trunc('month', o.order_purchase_timestamp)::date as month,
		sum(op.payment_value)::numeric as total_revenue
	from orders o 
	join order_payments op on o.order_id = op.order_id
	where op.payment_value > 0 
		and o.order_status not in ('canceled', 'unavailable')
	group by 1
),

--bikin kalender bulan biar ga loncat bulannya
calendar as (
	select generate_series(
		(select min(month) from monthly_revenue),
		(select max(month) from monthly_revenue),
		interval '1 month'
	)::date as month

),

--join supaya semua bulannya ada, kalo kosong jadi nol
filled as (
	select 
		c.month,
		coalesce(mr.total_revenue,0) as total_revenue
	from calendar c
	left join monthly_revenue mr on c.month = mr.month
),

finals as (
	select
		month,
		total_revenue,
		lag(total_revenue) over (order by month) as prev_month_revenue
	from filled
)

select
	extract(year from month) as year,
	extract(month from month) as month,
	round(total_revenue::numeric,2) as total_revenue,
	round(prev_month_revenue::numeric,2) as prev_month_revenue,
--	round(
--		((total_revenue - prev_month_revenue)
--		/nullif (prev_month_revenue, 0))::numeric 
--		*100 ,2) as mom_change_pct
	round(
		case
			when prev_month_revenue is null then null
			when prev_month_revenue = 0 then null
			else ((total_revenue - prev_month_revenue) / prev_month_revenue)::numeric *100
		end
	,2) as mom_change_pct
from finals
order by year, month;

--top 10 product categories by revenue
with valid_products as (
	select order_id 
	from orders 
	where order_status not in ('canceled', 'unavailable')
),

product_categories as (
	select 
		pcnt.product_category_name_english as category,
		oi.order_id,
		oi.price
	from order_items oi 
	join valid_products vp on oi.order_id = vp.order_id 
	join products p on oi.product_id = p.product_id 
	join product_category_name_translation pcnt on p.product_category_name = pcnt.product_category_name	
)

select 
	category,
	count(distinct order_id) as num_orders,
	count(*) as total_items_sold,
	round(sum(price)::numeric ,2) as total_revenue,
	round(sum(price)::numeric / count(distinct order_id),2) as avg_order_value
from product_categories
group by 1
order by total_revenue desc
limit 10;

--customer cohort retention
with first_purchase as(
	select 
		c.customer_unique_id,
		min(date_trunc('month', order_purchase_timestamp)) as cohort_month
	from orders o
	join customers c on o.customer_id = c.customer_id
	where order_status = 'delivered'
	group by 1
),

customer_orders as (
	select
		c.customer_unique_id, 
		date_trunc('month', order_purchase_timestamp) as order_month
	from orders o
	join customers c on o.customer_id = c.customer_id
	where order_status = 'delivered'
), 

cohort_cust as (
	select 
		fp.customer_unique_id,
		fp.cohort_month,
		co.order_month, 
		(extract(year from co.order_month) - extract (year from fp.cohort_month)) * 12 + 
		(extract (month from co.order_month) - extract (month from fp.cohort_month)) as month_diff
	from first_purchase fp 
	join customer_orders co on fp.customer_unique_id = co.customer_unique_id
)

select 
	to_char(cohort_month, 'YYYY-MM') as cohort_month,
	count(distinct customer_unique_id) as cohort_size,
	count(distinct case when cc.month_diff = 1 then customer_unique_id end) as retained_m1,
	count(distinct case when cc.month_diff = 2 then customer_unique_id end) as retained_m2,
	count(distinct case when cc.month_diff = 3 then customer_unique_id end) as retained_m3
from cohort_cust cc
group by cohort_month 
order by cohort_month;