-- Are there accounts that made multiple high-value transactions within minutes of each other?"
WITH  transaction_history AS (
  SELECT
    customer_key,
    transaction_datetime,
    amount_usd,
    -- time for the previous transaction for this specific user
    LAG(transaction_datetime) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_time,
    -- get the amount of the previous transaction
    LAG(amount_usd, 1, 0) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_amount
  FROM fact_transactions
)

-- filter the time difference
SELECT *
FROM transaction_history
  WHERE amount_usd = prev_amount
AND TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) <= 10;

-- 2. stress test since the above query returns non suspious amounts being transacted 
-- in a short period of time fraud is not happening the way it was expected
WITH  transaction_history AS (
  SELECT
    customer_key,
    transaction_datetime,
    amount_usd,
    -- time for the previous transaction for this specific user
    LAG(transaction_datetime) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_time,
    -- get the amount of the previous transaction
    LAG(amount_usd, 1, 0) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_amount
  FROM fact_transactions
)

-- filter the time difference
SELECT 
  *,
  (amount_usd - prev_amount) AS amount_diff,
  TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) AS minutes_between
FROM transaction_history
WHERE amount_usd BETWEEN (prev_amount * 0.95) AND (prev_amount * 1.05)
  AND prev_time IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) <= 10;

-- 3. stress test since the above query has no data meaning fraud is not happening the way it was expected,
-- lets show the difference in the amount
-- suspicious velocity transactions.
-- where amount is greater than average amount plus 3 times the standard deviation amountt
WITH  transaction_history AS (
  SELECT
    customer_key,
    transaction_datetime,
    amount_usd,
    channel,
    AVG(amount_usd) OVER(PARTITION BY channel) as avg_val,
    STDDEV(amount_usd) OVER(PARTITION BY channel) as std_val,
    LAG(transaction_datetime) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_time,
    LAG(amount_usd, 1, 0) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_amount
  FROM fact_transactions
)

SELECT 
  *,
  TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) AS minutes_between
FROM transaction_history
WHERE 
  prev_time IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) <= 10 
  AND amount_usd > (avg_val + (3 * std_val))
ORDER BY minutes_between ASC;


-- 4. count the rapid fire hits per user
WITH  transaction_history AS (
  SELECT
    customer_key,
    transaction_datetime,
    amount_usd,
    AVG(amount_usd) OVER(PARTITION BY channel) as avg_val,
    STDDEV(amount_usd) OVER(PARTITION BY channel) as std_val,
    LAG(transaction_datetime) OVER (PARTITION BY customer_key ORDER BY transaction_datetime) as prev_time
  FROM fact_transactions
), 
flagged_bursts AS (
  SELECT
    customer_key,
    amount_usd,
    TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) AS time_gap
  FROM transaction_history
  WHERE prev_time IS NOT NULL 
  AND TIMESTAMPDIFF(MINUTE, prev_time, transaction_datetime) <= 10
  AND amount_usd > (avg_val + (3 * std_val))
)
SELECT 
  fb.customer_key,
  dc.full_name,
  COUNT(*) AS total_burst_attempts,
  SUM(amount_usd) AS total_risk_value,
  AVG(amount_usd) AS avg_burst_amount
FROM flagged_bursts fb
LEFT JOIN dim_customer dc ON fb.customer_key = dc.customer_key
GROUP BY customer_key
ORDER BY total_burst_attempts DESC, total_risk_value DESC;
