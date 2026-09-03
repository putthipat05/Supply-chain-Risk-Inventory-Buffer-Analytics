--Supply chain risk analysis
--1.find the delay delivered supplier
select
b.supplier_name,
round(avg(a.actual_delivery_date - a.expected_delivery_date),2) as avg_delay_days,
round((sum(a.quantity_received) * 100) / nullif(sum(a.quantity_ordered),0),2) as fulfillment_rate_pct
from fact_purchase_orders as a
inner join dim_suppliers as b
on a.supplier_id = b.supplier_id
where status = 'COMPLETED'
group by b.supplier_name
order by avg_delay_days desc

--2.Critical Part Single-Source Concentration Risk
select
a.part_name,
count(distinct b.supplier_id) as supplier_count,
round(sum(b.quantity_ordered * a.unit_cost_usd),2) as total_spend_usd,
case
when count(distinct b.supplier_id) = 1 then 'Critical_single_source' 
else 'Diversified'
end as risk_level
from dim_parts as a
inner join fact_purchase_orders as b
on a.part_id = b.part_id
and criticality_tier = 'Tier 1'
group by part_name
order by total_spend_usd desc

--3.Core Capital Investmen
with total_spend as (select
part_name,
round(sum(quantity_ordered * unit_cost_usd),2) as total_spend_usd
from dim_parts as a
inner join fact_purchase_orders as b
on a.part_id = b.part_id
group by a.part_name
)

select
part_name,
total_spend_usd,
sum(total_spend_usd) over(order by total_spend_usd desc)as accumulative_spend_usd,
case 
when sum(total_spend_usd) over(order by total_spend_usd desc) 
<= sum(total_spend_usd) over() * 0.8 
then 'Core Top(80%)' 
else 'None core Buttom(20%)'
end as patero_tier
from total_spend
order by total_spend_usd desc


--4,Moving Average Lead Time & Buffer Assessment
select
a.po_id,
a.order_date,
(a.actual_delivery_date - a.order_date) as po_lead_time_days,
round(
      avg(a.actual_delivery_date - a.order_date)
      over(order by a.order_date  
	  rows between 2 preceding and current row ),2) as moving_avg_lead_time
from fact_purchase_orders as a
inner join dim_parts as b
on a.part_id = b.part_id
where b.part_name = 'High-NA EUV Mirror Module'
and a.status = 'COMPLETED'
order by order_date asc


--5.Executive Supply Chain Risk Matrix & Matrix Pivoting
with tier_1 as (
select
a.country,
sum(case when c.criticality_tier = 'Tier 1' then 1 else 0 end) as Tier1_orders,
sum(case when c.criticality_tier = 'Tier 2' then 1 else 0 end) as Tier2_orders,
sum(case when c.criticality_tier = 'Tier 3' then 1 else 0 end) as Tier3_orders,
count(b.po_id) as total_orders
from dim_suppliers as a
inner join fact_purchase_orders as b
on a.supplier_id = b.supplier_id
inner join dim_parts as c
on b.part_id = c.part_id
where b.status = 'COMPLETED'
group by
a.country
)

select
country,
Tier1_orders,
Tier2_orders,
Tier3_orders,
total_orders,
round((Tier1_orders * 100) / nullif(total_orders,0) ,2) as Tier1_ratio_pct
from tier_1
order by Tier1_ratio_pct desc
