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
![delay_supply](./images/supplier_delay.png)
