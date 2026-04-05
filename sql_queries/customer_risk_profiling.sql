-- For each customer, calculate: total transactions, total spend, average transaction value, most common channel, 
-- most common merchant category, and most common transaction hour.

WITH
  -- what is the most common channel per customer
  channel_counts AS (
    SELECT
      customer_key,
      channel,
      COUNT(*) as cnt
  FROM fact_transactions 
  GROUP BY customer_key, channel
),
channel_winner AS (
  SELECT customer_key, channel,
         ROW_NUMBER() OVER(PARTITION BY customer_key ORDER BY cnt DESC) as rn
  FROM channel_counts
),
-- what are the most common mechant category 
merchant_counts AS (
  SELECT ft.customer_key, dm.merchant_category, COUNT(*) as cnt
  FROM fact_transactions ft
  JOIN dim_merchant dm ON ft.merchant_key = dm.merchant_key
  GROUP BY ft.customer_key, dm.merchant_category
),
merchant_winner AS (
  SELECT customer_key, merchant_category,
         ROW_NUMBER() OVER(PARTITION BY customer_key ORDER BY cnt DESC) as rn
  FROM merchant_counts
),
-- most common transaction hour per customer
hour_counts AS (
  SELECT customer_key, transaction_hour, COUNT(*) as cnt
  FROM fact_transactions
  GROUP BY customer_key, transaction_hour
),
hour_winner AS (
  SELECT customer_key, transaction_hour,
         ROW_NUMBER() OVER(PARTITION BY customer_key ORDER BY cnt DESC) as rn
  FROM hour_counts
)
  
SELECT
  ft.customer_key,
  dc.full_name,
  COUNT(ft.transaction_id) AS total_transactions,
  SUM(ft.amount_usd) AS total_spend,
  AVG(ft.amount_usd) AS avg_transaction_value,
  cw.channel AS most_common_channel,
  mw.merchant_category AS most_common_category,
  hw.transaction_hour AS most_common_transaction_hour
FROM fact_transactions ft
LEFT JOIN dim_customer dc ON ft.customer_key = dc.customer_key
LEFT JOIN channel_winner cw ON ft.customer_key = cw.customer_key AND cw.rn = 1
LEFT JOIN merchant_winner mw ON ft.customer_key = mw.customer_key AND mw.rn = 1
LEFT JOIN hour_winner hw ON ft.customer_key = hw.customer_key AND hw.rn = 1
GROUP BY  ft.customer_key, cw.channel, mw.merchant_category, hw.transaction_hour;

-- 2.Identify customers who deviate from their own baseline
-- instead of using average use standard deviation as it is the industry standard of deviation
-- using avg only will not give the true picture

WITH customer_spend  AS (
  SELECT 
  dc.customer_key,
  dc.full_name,
  ft.amount_usd,
  AVG(ft.amount_usd) OVER(PARTITION BY dc.customer_key) as avg_spend,
  STDDEV(ft.amount_usd) OVER(PARTITION BY dc.customer_key) as std_spend
FROM fact_transactions ft
LEFT JOIN dim_customer dc ON ft.customer_key = dc.customer_key
)
SELECT *
FROM customer_spend
WHERE amount_usd > (avg_spend + (3 * std_spend));

-- 3. Count flags per customer
-- used rank to account for ties

WITH customer_fraud_flag  AS (
  SELECT 
  ft.customer_key, 
  dc.full_name as customer_name, 
  COUNT(*) AS total_fraud_flags, 
  RANK() OVER(ORDER BY COUNT(*) DESC) AS fraud_risk_rank
FROM suspicious_transactions_view stv
LEFT JOIN fact_transactions ft ON stv.transaction_id = ft.transaction_id
LEFT JOIN dim_customer dc ON ft.customer_key = dc.customer_key
WHERE total_flag_count >= 3 
GROUP BY ft.customer_key, dc.full_name
)

SELECT 
  *,
  CASE
      WHEN fraud_risk_rank < 10 THEN 'High Risk'
      WHEN fraud_risk_rank BETWEEN 10 AND 15 THEN 'Medium Risk'
      ELSE 'Low Risk'
  END AS risk_group
FROM customer_fraud_flag
WHERE fraud_risk_rank <= 20;
