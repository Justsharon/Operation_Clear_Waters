-- 1. off hours activities
SELECT
  channel,
  COUNT(transaction_id) as total_transactions,
  SUM(amount_usd) as total_transaction_value,
  transaction_hour
FROM fact_transactions
WHERE transaction_hour  >= 1 AND transaction_hour < 4
GROUP BY channel, transaction_hour
ORDER BY total_transactions DESC, total_transaction_value DESC;

-- 2. Find transactions that are statistical outliers significantly above the average.
SELECT *
FROM (
  SELECT 
    transaction_id,
    amount_usd,
    channel,
    AVG(amount_usd) OVER(PARTITION BY channel) as avg_val,
    STDDEV(amount_usd) OVER(PARTITION BY channel) as std_val
FROM fact_transactions
) AS stats
  
WHERE amount_usd > (avg_val + (3 * std_val))
ORDER BY amount_usd DESC;

-- 3. transactions where the transaction country doesn't match the customer's registered country.
SELECT 
  dc.full_name,
  dc.country AS registered_country,
  dl.country AS transaction_country
FROM fact_transactions ft
INNER JOIN dim_location dl ON ft.location_key = dl.location_key
INNER JOIN dim_customer dc ON ft.customer_key = dc.customer_key
WHERE dl.country != dc.country;


-- 4. Flag and tag suspicious transactions
-- For every transaction in the bank's history, this query calculates four independent fraud signals
-- off-hours activity, geographic mismatch, statistical amount outlier, and velocity anomaly
-- and combines them into a total flag score. Transactions are ranked with the highest-risk, highest-value first.
CREATE VIEW suspicious_transactions_view AS
WITH outlier_stats AS (
  SELECT *
    FROM (
      SELECT 
        transaction_id,
        amount_usd,
        channel,
        AVG(amount_usd) OVER(PARTITION BY channel) as avg_val,
        STDDEV(amount_usd) OVER(PARTITION BY channel) as std_val
    FROM fact_transactions
) AS stats
  
WHERE amount_usd > (avg_val + (3 * std_val))
),
  
transaction_history AS (
  SELECT
    transaction_id,
    customer_key,
    transaction_datetime,
    amount_usd,
    channel,
    AVG(amount_usd) OVER(PARTITION BY channel) as avg_val,
    STDDEV(amount_usd) OVER(PARTITION BY channel) as std_val,
    LAG(transaction_datetime) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_time,
    LAG(amount_usd) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_amount
  FROM fact_transactions
),
  
velocity_flags AS (
  SELECT 
  *,
  TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) AS minutes_between,
  -- Flag logic combining velocity (time) and value (z-score)
  CASE 
    WHEN prev_time IS NOT NULL 
     AND TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) <= 10 
     AND amount_usd > (avg_val + (3 * std_val)) 
    THEN 1 
    ELSE 0 
  END AS is_velocity
FROM transaction_history
)
  
SELECT 
  ft.transaction_id,
  ft.amount_usd,
  dc.country AS registered_country,
  dl.country AS transaction_country,
  CASE WHEN transaction_hour  >= 1 AND transaction_hour < 4 THEN 1 ELSE 0 END AS is_offhours_flag,
  CASE WHEN dl.country != dc.country THEN 1 ELSE 0 END AS is_geomismatch_flag,
  CASE WHEN os.transaction_id IS NOT NULL THEN 1 ELSE 0 END AS is_outlier_flag,
  COALESCE(vf.is_velocity, 0) AS is_velocity_flag,
  (
    (CASE WHEN HOUR(ft.transaction_datetime) >= 1 AND HOUR(ft.transaction_datetime) < 4 THEN 1 ELSE 0 END) +
    (CASE WHEN dl.country != dc.country THEN 1 ELSE 0 END) +
    (CASE WHEN os.transaction_id IS NOT NULL THEN 1 ELSE 0 END) +
    (COALESCE(vf.is_velocity, 0))
  ) AS total_flag_count,
FROM fact_transactions ft
LEFT JOIN dim_location dl ON ft.location_key = dl.location_key
LEFT JOIN dim_customer dc ON ft.customer_key = dc.customer_key
LEFT JOIN velocity_flags vf ON ft.transaction_id = vf.transaction_id
LEFT JOIN outlier_stats os ON ft.transaction_id = os.transaction_id
ORDER BY total_flag_count DESC, amount_usd DESC;