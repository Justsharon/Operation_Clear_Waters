-- total transaction volume
select 
  count(transaction_id) as number_of_transactions, 
  sum(amount_usd) as total_transactions,
  avg(amount_usd) as avg_transactions
from fact_transactions;

-- total transction amount per transaction type
select 
  sum(amount_usd) as total, 
  transaction_type 
from fact_transactions ft  
group by transaction_type
order by total desc;

-- total transction amount per chanel
select 
  sum(amount_usd) as total, 
  channel 
from fact_transactions ft  
group by channel
order by total desc;

-- which quarter had the most transactions
select 
  sum(ft.amount_usd) as total, 
  dt.quarter_name
from fact_transactions ft  
inner join dim_date dt
on ft.date_key = dt.date_key
group by dt.quarter_name
order by total desc;

-- which month had the most transactions
SELECT 
    dt.month_name,  -- Better for labels
    dt.month_number, -- Use this for sorting
    SUM(ft.amount_usd) AS total_value, 
    COUNT(ft.transaction_id) AS total_volume
FROM fact_transactions ft  
INNER JOIN dim_date dt ON ft.date_key = dt.date_key
GROUP BY dt.month_name, dt.month_number
ORDER BY total_value DESC;

-- Which locations generate the most transactions?
SELECT 
    dl.country,  
    dl.region, 
    AVG(ft.amount_usd) AS average_value, 
    COUNT(ft.transaction_id) AS total_volume
FROM fact_transactions ft  
INNER JOIN dim_location dl ON ft.location_key = dl.location_key
GROUP BY dl.country, dl.region
ORDER BY average_value DESC;

-- Which merchant categories see the most spend?
SELECT 
    dm.merchant_category, 
    SUM(ft.amount_usd) AS total_spend, 
    COUNT(ft.transaction_id) AS total_volume
FROM fact_transactions ft  
INNER JOIN dim_merchant dm ON ft.merchant_key = dm.merchant_key
GROUP BY dm.merchant_category
ORDER BY total_spend DESC;
