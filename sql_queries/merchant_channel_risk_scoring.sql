-- Merchant risk scoring
WITH merchant_risk_stats AS (
 SELECT 
    dm.merchant_category,
    dm.merchant_key,
    COUNT(ft.transaction_id) as total_transaction_count,
    COUNT(CASE WHEN ft.is_flagged = 1 THEN  1 END) AS flagged_total_transaction_count,
    SUM(CASE WHEN ft.is_flagged = 1 THEN ft.amount_usd ELSE 0 END) AS flagged_total_transactions_value
  FROM fact_transactions ft
  LEFT JOIN dim_merchant dm ON ft.merchant_key = dm.merchant_key  
  GROUP BY dm.merchant_category, dm.merchant_key
)
SELECT 
    *,
    (CAST(flagged_total_transaction_count AS DECIMAL) / NULLIF(total_transaction_count, 0)) * 100 as flagged_percentage,
    RANK() OVER(ORDER BY (CAST(flagged_total_transaction_count AS DECIMAL) / NULLIF(total_transaction_count, 0)) DESC) AS risk_rnk
FROM merchant_risk_stats;

-- Channel risk scoring
WITH channel_risk_stats AS (
 SELECT 
    ft.channel,
    COUNT(ft.transaction_id) as total_transaction_count,
    COUNT(CASE WHEN ft.is_flagged = 1 THEN  1 END) AS flagged_total_transaction_count,
    SUM(CASE WHEN ft.is_flagged = 1 THEN ft.amount_usd ELSE 0 END) AS flagged_total_transactions_value
  FROM fact_transactions ft
  GROUP BY ft.channel
)
SELECT 
    *,
    (CAST(flagged_total_transaction_count AS DECIMAL) / NULLIF(total_transaction_count, 0)) * 100 as flagged_percentage,
    RANK() OVER(ORDER BY (CAST(flagged_total_transaction_count AS DECIMAL) / NULLIF(total_transaction_count, 0)) DESC) AS risk_rnk
FROM channel_risk_stats;

-- which channel and hour combinations  are highest risk
WITH channel_hour_stats AS (
 SELECT 
    ft.channel,
    COUNT(ft.transaction_id) as total_transaction_count,
    ft.transaction_hour,
    COUNT(CASE WHEN ft.is_flagged = 1 THEN  1 END) AS flagged_total_transaction_count,
    SUM(CASE WHEN ft.is_flagged = 1 THEN ft.amount_usd ELSE 0 END) AS flagged_total_transactions_value
  FROM fact_transactions ft
  GROUP BY ft.channel, ft.transaction_hour
),
channel_hours AS (
  SELECT 
    *,
    (CAST(flagged_total_transaction_count AS DECIMAL) / NULLIF(total_transaction_count, 0)) * 100 as flagged_percentage,
    RANK() OVER(ORDER BY (CAST(flagged_total_transaction_count AS DECIMAL) / NULLIF(total_transaction_count, 0)) DESC) AS risk_rnk
FROM channel_hour_stats
)
  
SELECT 
  *,
   CASE
        WHEN risk_rnk < 4 THEN 'High Risk'
        WHEN risk_rnk BETWEEN 4 AND 7 THEN 'Medium Risk'
        ELSE 'Low Risk'
  END AS risk_group
FROM channel_hours
WHERE risk_rnk <= 10;

