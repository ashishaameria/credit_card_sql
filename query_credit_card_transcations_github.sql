--1- top 5 cities with highest spends and their percentage contribution of total credit card spends

select top 5 city, sum(amount) as total_spend, 
cast(100.0*sum(amount)/(select sum(amount) as grand_total from credit_card_transcations) as decimal(4,2)) as percent_share
from credit_card_transcations
group by city
order by total_spend desc

--2- highest spend month and amount spent in that month for each card type

with cte1 as
(select datepart(year, transaction_date) as transaction_year,
datename(month, transaction_date) as transaction_month, card_type,
sum(amount) as amount_spent
from credit_card_transcations
group by datepart(year, transaction_date), datename(month, transaction_date), card_type)

select transaction_year, transaction_month, card_type, amount_spent from
(select *,
row_number () over(partition by card_type order by amount_spent desc) as rn
from cte1)a
where rn=1

--3- transaction details for each card type when it reaches a cumulative of 1000000 total spends

with cte1 as
(select *,
sum(amount) over(partition by card_type order by transaction_date, transaction_id) as cumulative_spend
from credit_card_transcations),

cte2 as
(select *,
row_number() over(partition by card_type order by cumulative_spend) as rn
from cte1
where cumulative_spend > 1000000)

select * 
from cte2 where rn = 1

--4- city which had lowest percentage spend for gold card type among all other card types

select top 1 city,
sum(amount) as total_spend,
sum(case when card_type = 'gold' then amount else 0 end) total_gold_spend,
cast(100.0*sum(case when card_type = 'gold' then amount else 0 end)/sum(amount) as decimal(6,2)) as gold_percent_share
from credit_card_transcations
group by city
having sum(case when card_type = 'gold' then amount else 0 end) > 0
order by 4

--5- query to print 3 columns:  city, highest_expense_type , lowest_expense_type for all the cities
--(example format : Delhi , bills, Fuel)

with cte1 as(
select *,
row_number() over(partition by city order by total_spend) as rn_asc,
row_number() over(partition by city order by total_spend desc) as rn_desc
from
(select city, exp_type, sum(amount) as total_spend
from credit_card_transcations
group by city, exp_type) a
)

select city,
max(case when rn_desc = 1 then exp_type end) as highest_expense,
max(case when rn_asc = 1 then exp_type end) as lowest_expense
from cte1
where rn_asc = 1 or rn_desc = 1
group by city

--6- percentage contribution of spends by females for each expense type

with cte1 as
(select exp_type, gender, 
sum(amount) over(partition by gender, exp_type) as F_total_spend,
sum(amount) over(partition by exp_type) as overall_total_spend,
cast(100.0*sum(amount) over(partition by gender, exp_type)/sum(amount) over(partition by exp_type) as decimal(4,2)) as percent_share
from credit_card_transcations)

select distinct * from cte1
where gender = 'F'

--7- card and expense type combination saw highest month over month growth in Jan-2014

with cte1 as
(select distinct card_type, exp_type,
format(transaction_date, 'yyyy-MM') as transaction_year_month,
sum(amount) over(partition by card_type, exp_type, datepart(year, transaction_date), datepart(month, transaction_date)) as jan14_spend
from credit_card_transcations
where format(transaction_date, 'yyyy-MM') in ('2014-01', '2013-12'))

,cte2 as (
select *,
lag(jan14_spend) over(partition by card_type, exp_type order by transaction_year_month) as dec13_spend
from cte1
)

select top 1 *,
cast(100.0*(jan14_spend-dec13_spend)/dec13_spend as decimal(4,2)) as MOM_percecnt
from cte2
where dec13_spend is not null
order by 6 desc

--8- city had highest total spend to total no of transcations ratio during weekends

select top 1 city, sum(amount) as weekend_spend, count(1) as total_transaction,
sum(amount)/count(1) as weeken_spend_by_total_transaction_ratio
from credit_card_transcations
where datename(weekday, transaction_date) in ('Saturday', 'Sunday')
group by city
order by 4 desc

--9- city took least number of days to reach its 500th transaction after the first transaction in that city 

with cte1 as
(select *,
row_number() over(partition by city order by transaction_date) as rn
from credit_card_transcations)

,cte2 as(
select *,
FIRST_VALUE(transaction_date) over(partition by city order by transaction_date) as FV
from cte1
)

select top 1*,
datediff(day, FV, transaction_date) as gap_days_500_transaction
from cte2 where rn = 500
order by 10