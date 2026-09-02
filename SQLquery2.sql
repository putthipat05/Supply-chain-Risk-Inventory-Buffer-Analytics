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
