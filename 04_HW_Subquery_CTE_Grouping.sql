-- 1.1. In the fact_transaction_2019 data table, each successful transaction corresponds to a different category.
--  Calculate the number of transactions of each category to make reporting easier.

SELECT category
   ,COUNT(transaction_id) as number_trans
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS sce
   ON sce.scenario_id = fact_19.scenario_id
LEFT JOIN dim_status AS stat
   ON fact_19.status_id = stat.status_id
WHERE status_description = 'success'
GROUP BY category;


-- 1.2 Query practice with a CTE table
-- Step 1: Create a CTE to store a temporary table containing information about all transactions in 2019 that satisfy the conditions of successful
--  transactions and payment by the "Bank account" method. Select the information: transaction_id, customer_id, charged_amount, platform_id.
-- Step 2: Join with dim_platform table to retain transactions made with “Android” device


WITH trans_table AS (
   SELECT transaction_id
   , customer_id
   , charged_amount
   , platform_id
   FROM fact_transaction_2019 AS fact_19
   JOIN dim_payment_channel AS chan  
   ON fact_19.payment_channel_id = chan.payment_channel_id
   WHERE payment_method = 'Bank account' AND status_id in (SELECT status_id FROM dim_status WHERE status_description = 'success')
)

SELECT transaction_id
   ,customer_id
   ,charged_amount
   ,payment_platform
FROM trans_table
JOIN dim_platform AS plt
ON plt.platform_id = trans_table.platform_id
WHERE payment_platform = 'android'


-- 1.3. Use nested queries (Subquery) and CTE.
-- Please indicate the total number of transactions of each transaction_type, provided: successful transaction, transaction time in the first 3 months of 2019
-- Calculate the ratio of the number of transactions of each type to the total number of transactions in 3 months.
-- The basic solution of this article will be as follows:
--  I need to create a CTE that selects data that meets the requirements of the problem.
--  Create a CTE: Pool, calculate the number of transactions of each type and the total number of successful transactions of the first 3 months
--  Displays the top 5 transaction types with the highest number of transactions and the ratio of each type


--- Bước 1: CTE thoả mãn yêu cầu thành công và giao dịch trong 3 tháng đầu tiên
WITH joined_table AS (
SELECT fact_19.*
   , transaction_type
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_status AS stt
   ON fact_19.status_id = stt.status_id 
LEFT JOIN dim_scenario AS sce
   ON fact_19.scenario_id = sce.scenario_id
WHERE status_description = 'Success'
   AND MONTH(transaction_time) IN (1, 2, 3) 
)
--- Bước 2: CTE gom nhóm và tính toán theo từng loại giao dịch.
-- NOTES: Từ CTE thứ hai trở đi chúng ta sẽ sử dụng dấu ',' để ngăn cách các CTE như bên dưới
, total_table AS (
SELECT transaction_type
   , COUNT(transaction_id) AS number_trans
   ,(SELECT COUNT(transaction_id) FROM joined_table) AS total_trans -- subquery lấy ra total trans
FROM joined_table
GROUP BY transaction_type
)
--Bước 3: Hiển thị vừa đủ thông tin đề yêu cầu
SELECT TOP 5 *
   , FORMAT ( CAST(number_trans AS float)/total_trans, 'p') as pct 
FROM total_table
ORDER BY CAST(number_trans AS float)/total_trans DESC



-- PART 2: APPLYING FOR EXERCISES

-- Task 1: Retrieve an overview report of payment types
-- Paytm has a wide variety of transaction types in its business. Your manager wants to know the contribution (by percentage) 
-- of each transaction type to total transactions. Retrieve a report that includes the following information: 
-- transaction type, number of transactions and proportion of each type in total. These transactions must meet the following conditions: 
-- Were created in 2019 
-- Were paid successfully
-- Show only the results of the top 5 types with the highest percentage of the total.



WITH joined_table AS (
SELECT fact_19.*
   , transaction_type
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_status AS stt
   ON fact_19.status_id = stt.status_id 
LEFT JOIN dim_scenario AS sce
   ON fact_19.scenario_id = sce.scenario_id
WHERE status_description = 'Success'
)

, total_table AS (
SELECT transaction_type
   , COUNT(transaction_id) AS number_trans
   ,(SELECT COUNT(transaction_id) FROM joined_table) AS total_trans
FROM joined_table
GROUP BY transaction_type
)

SELECT TOP 5 *
   , FORMAT ( CAST(number_trans AS float)/total_trans, 'p') as pct 
FROM total_table
ORDER BY CAST(number_trans AS float)/total_trans DESC



-- 1.2. After your manager looks at the results of these top 5 types, he wants to deep dive more to gain more insights. 
-- Retrieve a more detailed report with following information: transaction type, category, number of transactions 
-- and proportion of each category in the total of that transaction type. These transactions must meet the following conditions: 
-- Were created in 2019 
-- Were paid successful


WITH joined_table AS (
    SELECT fact_19.*
    , transaction_type
    , category
    FROM fact_transaction_2019 AS fact_19
    LEFT JOIN dim_status AS stt
    ON fact_19.status_id = stt.status_id 
    LEFT JOIN dim_scenario AS sce
    ON fact_19.scenario_id = sce.scenario_id
    WHERE status_description = 'Success'
)

, type_table AS (
    SELECT transaction_type
    , COUNT(transaction_id) AS number_trans_type
    FROM joined_table
    GROUP BY transaction_type
)

, type_cat_table AS (
    SELECT transaction_type
        , category
    , COUNT(transaction_id) AS number_trans_category
    FROM joined_table
    GROUP BY transaction_type, category
)

, total_table AS (
    SELECT type_cat_table.*
        , number_trans_type
    FROM type_cat_table
    LEFT JOIN type_table
        ON type_cat_table.transaction_type = type_table.transaction_type
)

SELECT *
   , FORMAT ( CAST(number_trans_category AS float)/number_trans_type, 'p') as pct -- dùng format thì kết quả ra string
FROM total_table
ORDER BY transaction_type, pct DESC




-- Task 2: Retrieve an overview report of customer’s payment behaviors ( hành vi thanh toán khách hàng ) 
-- Paytm has acquired a lot of customers. Retrieve a report that includes the following information:
--  the number of transactions, the number of payment scenarios, the number of payment categories and the total of charged amount of each customer.
-- Were created in 2019
-- Had status description is successful
-- Had transaction type is payment


WITH joined_table AS (
    SELECT fact_19.*
    , transaction_type
    , category
    FROM fact_transaction_2019 AS fact_19
    LEFT JOIN dim_status AS stt
    ON fact_19.status_id = stt.status_id 
    LEFT JOIN dim_scenario AS sce
    ON fact_19.scenario_id = sce.scenario_id
    WHERE status_description = 'Success'
    AND transaction_type = 'Payment' 
)

SELECT customer_id
    , COUNT(transaction_id) AS number_trans
    , COUNT (DISTINCT scenario_id) AS number_scenarios
    , COUNT(DISTINCT category) AS number_categories
    , SUM(charged_amount) AS total_amount
    -- ngày cuối cùng khách hàng thanh toán
    , FORMAT(MAX(transaction_time), 'yyyy-MM-dd') AS latest_day  -- data type là date
    -- , CONVERT(DATE, MAX(transaction_time)) AS latest_day  -- data type là string
    -- đánh index thì sẽ nhanh hơn
FROM joined_table
GROUP BY customer_id
ORDER BY number_trans DESC




-- 2.2. OPTIONAL
-- Phân loại khách hàng giao dịch thành công  thành 3 nhóm: 
-- Tổng số tiền giao dịch trên 5.000.000 là “New Customer”
-- Tổng số tiền giao dịch trên 10.000.000 là “Potential Customer”
-- Tổng số tiền giao dịch trên 50.000.000 là “Loyal Customer”

-- CASE WHEN

WITH table_amount AS (
    SELECT customer_id
        , SUM(charged_amount)  AS total_amount
    FROM fact_transaction_2019 AS fact_19
    LEFT JOIN dim_status AS stt
    ON fact_19.status_id = stt.status_id 
    WHERE status_description = 'Success'
    GROUP BY customer_id
)

, table_label AS (
    SELECT *
    , CASE WHEN total_amount > 50000000 THEN 'Loyal customer'
        WHEN total_amount > 10000000 THEN 'Potential customer'
        WHEN total_amount > 5000000 THEN 'New Customer'
        ELSE 'lower than 5M'
        END AS label 
    FROM table_amount
)

SELECT label
    , count(customer_id) AS number_customers
FROM table_label
GROUP BY label;

-- tỷ lệ các giao dịch hưởng khuyến mãi (promotion_id != 0)
-- sp thanh toán hóa đơn Telecom theo từng tuần trong 2019

-- cách 1:

WITH electric_trans AS (
    SELECT fact_19.*
    FROM fact_transaction_2019 as fact_19
    LEFT JOIN dim_scenario as sce
    ON fact_19.scenario_id = sce.scenario_id
    LEFT JOIN dim_status as stat
    ON fact_19.status_id = stat.status_id
    WHERE category = 'Telco'
    AND status_description = 'Success'
)
, promotion_trans AS (
    select *
        , COUNT(transaction_id) AS number_p_trans
    FROM electric_trans
    WHERE promotion_id <> 0
    GROUP BY week_of_year
)
, grouped_trans AS (

    SELECT week_of_year
        , COUNT(transaction_id) AS number_p_trans
    
    FROM electric_trans
    GROUP BY week_of_year
    
)

-- join

SELECT *
   , FORMAT ( CAST(number_p_trans AS float)/total_trans, 'p') as pct -- dùng format thì kết quả ra string
FROM grouped_trans
ORDER BY week_of_year

-- cách 2:

WITH table_week AS (
SELECT transaction_id, transaction_time, promotion_id
, DATEPART (week, transaction_time) AS week_number
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario as sce
ON fact_19.scenario_id = sce.scenario_id
LEFT JOIN dim_status as stat
ON fact_19.status_id = stat.status_id
WHERE category = 'Telco'
AND status_description = 'Success'
)


SELECT week_number
    , COUNT (CASE WHEN promotion_id <> '0' THEN transaction_id END) AS number_promotion_trans
    , COUNT (transaction_id) as total_trans
    , FORMAT(CAST( COUNT (CASE WHEN promotion_id <> '0' THEN transaction_id END) AS DECIMAL) / COUNT (transaction_id), 'p') AS pct
FROM table_week
GROUP BY week_number
ORDER BY week_number

-- trans_num : điện, nước, TV trong mỗi tuần

WITH table_week AS (
    SELECT transaction_id, transaction_time, promotion_id, sub_category
    , DATEPART (week, transaction_time) AS week_number
    FROM fact_transaction_2019 as fact_19
    LEFT JOIN dim_scenario as sce
    ON fact_19.scenario_id = sce.scenario_id
    LEFT JOIN dim_status as stat
    ON fact_19.status_id = stat.status_id
    WHERE sub_category IN ('Electricity', 'Water', 'TV')
    AND status_description = 'Success'
)

SELECT  COUNT (CASE WHEN sub_category = 'Electricity' THEN transaction_id END) AS number_electricity
    ,  COUNT (CASE WHEN sub_category = 'Water' THEN transaction_id END) AS number_water
    , COUNT (CASE WHEN sub_category = 'TV' THEN transaction_id END) AS number_TV
FROM table_week
GROUP BY week_number
ORDER BY week_number


-- SUBQUERIES - CTE : DONE