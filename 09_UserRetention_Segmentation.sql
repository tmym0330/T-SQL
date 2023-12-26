
-- LESSON 9: COHORT ANALYSIS & SEGMENTATION

WITH sub_table AS (
SELECT customer_id, transaction_id, transaction_time
, MIN ( MONTH (transaction_time) ) OVER ( PARTITION BY customer_id ) AS first_month
, DATEDIFF (month, MIN (transaction_time) OVER ( PARTITION BY customer_id ) , transaction_time ) AS subsequent_month
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat
ON fact_19.status_id = stat.status_id
WHERE sub_category = 'Telco Card'
AND status_description = 'success'
-- ORDER BY customer_id, transaction_time
)
, retain_table AS (
SELECT first_month, subsequent_month
, COUNT ( DISTINCT customer_id) AS retained_customers
FROM sub_table
GROUP BY first_month, subsequent_month
)

-- lưu vào bảng tạm (trong phiên làm việc)
SELECT *
, FIRST_VALUE (retained_customers) OVER ( PARTITION BY first_month ORDER BY subsequent_month ) AS original_customer
, FORMAT (CAST (retained_customers AS FLOAT) / FIRST_VALUE (retained_customers) OVER ( PARTITION BY first_month ORDER BY subsequent_month ), 'p') AS pct_retained
INTO #retention_table
FROM retain_table


-- 1.2 B: Pivot Table


SELECT first_month, original_customer
, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"
FROM ( -- Nhớ là phải chọn đúng những columns mình cần thôi
SELECT first_month, subsequent_month, original_customer, pct_retained -- STRING
FROM #retention_table
) AS source_table
PIVOT (
MIN (pct_retained)
FOR subsequent_month IN ( "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11" )
) AS pivot_logic
ORDER BY first_month


-- II. USER SEGMENTATION:
-- Task 2.1. The first step in building an RFM model is to assign Recency, Frequency and Monetary values
-- to each customer. Let’s calculate these metrics for all successful paying customer of ‘Telco Card’
-- in 2019 and 2020:




WITH join_table AS (
SELECT transaction_id
, customer_id
, CONVERT(DATE, transaction_time) AS trans_date
, charged_amount
FROM (
SELECT * FROM fact_transaction_2019
UNION
SELECT *
FROM fact_transaction_2020 ) AS fact_table
JOIN dim_scenario AS sce
ON fact_table.scenario_id = sce.scenario_id
WHERE sub_category = 'Telco Card'
AND status_id = 1
)
, table_rfm AS (
SELECT customer_id
, SUM(charged_amount) AS Monetary
, COUNT (DISTINCT trans_date) AS Frequency
, DATEDIFF(day, CONVERT(DATE, MAX(trans_date)),'2020-12-31') AS Recency
FROM join_table
GROUP BY customer_id
)
, table_rank AS (
SELECT *
, PERCENT_RANK () OVER ( ORDER BY Monetary DESC ) AS m_rank
, PERCENT_RANK () OVER ( ORDER BY Frequency DESC ) AS f_rank
, PERCENT_RANK () OVER ( ORDER BY Recency ASC ) AS r_rank
FROM table_rfm
)

, table_tier AS (
SELECT *
, CASE WHEN m_rank > 0.75 THEN 4
WHEN m_rank > 0.5 THEN 3
WHEN m_rank > 0.25 THEN 2
ELSE 1 END m_tier
, CASE WHEN f_rank > 0.75 THEN 4
WHEN f_rank > 0.5 THEN 3
WHEN f_rank > 0.25 THEN 2
ELSE 1 END f_tier
, CASE WHEN r_rank > 0.75 THEN 4
WHEN r_rank > 0.5 THEN 3
WHEN r_rank > 0.25 THEN 2
ELSE 1 END r_tier
FROM table_rank
)



, table_score AS (
SELECT *
, CONCAT (r_tier, f_tier, m_tier) AS rfm_score
FROM table_tier
)
SELECT *
, CASE
WHEN rfm_score = 111 THEN 'Best Customers' -- KH tốt nhất
WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer' -- KH rời bỏ mà còn siêu tệ (F <= 2 )
WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' -- KH cũng rời bỏ nhưng có valued (F = 3,4,5 )
WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost' -- sắp lost những KH này
WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' -- chi nhiều tiền
WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' -- KH mới nên là giao dịch ít
WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' -- ngủ đông (trc đó từng rất là tốt )
WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' -- có tiềm năng
ELSE 'unknown' END AS segment
FROM table_score