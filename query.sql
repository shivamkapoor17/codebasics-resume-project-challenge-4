-- 1

SELECT distinct market FROM dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';
--------------------------------------------------------
-- 2
with cte1 as (
select count(distinct product_code) as unique_products_2021 from fact_manufacturing_cost
where cost_year = '2021'
),
cte2 as (
select count(distinct product_code) as unique_products_2020 from fact_manufacturing_cost
where cost_year = '2020' 
)
select unique_products_2021, unique_products_2020, round((unique_products_2021 - unique_products_2020)*100/unique_products_2020, 2) as percentage_chg from cte1
cross join cte2;
-----------------------------------------------------------------------------------------
-- 3
select segment, count(product_code) as product_count from dim_product 
group by segment
order by product_count desc;
---------------------------------------------------------------
-- 4

with cte1 as (
select a.segment, count(b.cost_year) as product_count_2021 from dim_product a
inner join fact_manufacturing_cost b on a.product_code = b.product_code
where b.cost_year = '2021'
group by a.segment
),
cte2 as (
select c.segment, count(d.cost_year) as product_count_2020  from dim_product c
inner join fact_manufacturing_cost d on c.product_code = d.product_code
where d.cost_year = '2020'
group by c.segment
) 
select cte1.segment, cte1.product_count_2021, cte2.product_count_2020, cte1.product_count_2021-cte2.product_count_2020 as difference from cte1
inner join cte2 on cte1.segment = cte2.segment; 
-------------------------------------------------------------------------
-- 5

select fact_manufacturing_cost.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost from fact_manufacturing_cost
inner join dim_product on fact_manufacturing_cost.product_code = dim_product.product_code
where fact_manufacturing_cost.manufacturing_cost = ( select max(fact_manufacturing_cost.manufacturing_cost) from fact_manufacturing_cost) or fact_manufacturing_cost.manufacturing_cost = ( select min(fact_manufacturing_cost.manufacturing_cost) from fact_manufacturing_cost);
----------------------------------------------------------------------
-- 6

select a.customer_code, b.customer, avg(a.pre_invoice_discount_pct)*100 +'%' as average_discount_percentage from dim_customer b 
inner join fact_pre_invoice_deductions a on a.customer_code = b.customer_code
where a.fiscal_year =2021 and market = 'India'
group by b.customer, a.customer_code
order by average_discount_percentage desc
limit 5;

-- or  

select b.customer, avg(a.pre_invoice_discount_pct)*100 +'%' as average_discount_percentage from fact_pre_invoice_deductions a
inner join dim_customer b on a.customer_code = b.customer_code
where a.fiscal_year =2021 and market = 'India'
group by b.customer
order by average_discount_percentage desc
limit 5;
-------------------------------------------------------------------------------
-- 7


with cte as(
select extract(month from a.date) as month1, extract(year from a.date) as year, round(sum(a.sold_quantity * c.gross_price)/1000000, 2) as gross_sales_ammount from ((fact_sales_monthly a
inner join dim_customer b on a.customer_code = b.customer_code)
inner join fact_gross_price c on a.product_code = c.product_code)
where b.customer = 'Atliq Exclusive'
group by month1, year
order by year , month1
)
select 
case
	when month1 = 1 then 'January'
    when month1 = 2 then 'February'
    when month1 = 3 then 'March'
    when month1 = 4 then 'April'
    when month1 = 5 then 'May'
    when month1 = 6 then 'June'
    when month1 = 7 then 'July'
    when month1 = 8 then 'August'
    when month1 = 9 then 'September'
    when month1 = 10 then 'October'
    when month1 = 11 then 'November'
    when month1 = 12 then 'December'
	else ''
end as month,
year, gross_sales_ammount
from cte;


-------------------------------------------------------------------------------------------------
-- 8


with cte as (
select date, fiscal_year, sold_quantity,
case 
	when date between '2019-09-01' and '2019-11-30' then 1
    when date between '2019-12-01' and '2020-02-29' then 2
    when date between '2020-03-01' and '2020-05-31' then 3
    when date between '2020-06-01' and '2020-08-31' then 4
	else ''
	
END AS Quarter
from fact_sales_monthly
where fiscal_year = '2020'

)
select Quarter , sum(sold_quantity) as total_sold_quantity from cte
group by Quarter
order by total_sold_quantity desc;


-------------------------------------------------------------------------------------------
-- 9

with cte as (
select c.channel, round(sum(b.gross_price * a.sold_quantity)/1000000, 2) as gross_sales_mln from ((fact_sales_monthly a
inner join  fact_gross_price b on a.product_code = b.product_code)
inner join dim_customer c on a.customer_code = c.customer_code)
where a.fiscal_year = '2021'
group by channel
)

select channel, gross_sales_mln, round(sum(gross_sales_mln) over (partition by channel)*100/sum(gross_sales_mln) over (), 2) as percentage from cte
group by channel;

----------------------------------------------------------------------------------------

-- 10
with cte as (
select a.division, a.product_code, a.product, sum(sold_quantity) over(partition by division, product_code, product) as total_sold_quantity from dim_product a
inner join fact_sales_monthly b on a.product_code = b.product_code
where b.fiscal_year = '2021'
)
select * from (
select distinct product_code, division, product, total_sold_quantity,  dense_rank() over(partition by division
order by total_sold_quantity desc) as rank_order from cte ) table1
where rank_order <= 3;














