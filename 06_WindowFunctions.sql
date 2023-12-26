-- LESSON 6: WINDOW FUNCTIONs -- Hàm cửa sổ


-- 1. Dùng Window function để tính tổng (COUNT, MIN, MAX, SUM, AVG )


-- ex1: Hãy cho biết số lượng giao dịch của từng tháng trong năm 2019 ( chỉ lấy category = 'Telco' )


-- Output: Month, Number_of_trans


-- cách 1: Group BY tháng và đếm giao dịch


SELECT MONTH (transaction_time) AS [month]
, COUNT (transaction_id ) AS number_of_trans
FROM fact_transaction_2019 AS fact_19
JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
WHERE category = 'Telco'
GROUP BY MONTH (transaction_time)
ORDER BY [month]

-- CÁCH 2: WINDOW FUNCTION
WITH table_month AS (
SELECT transaction_time, transaction_id
, MONTH (transaction_time) AS [month]
FROM fact_transaction_2019 AS fact_19
JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
WHERE category = 'Telco'
)
SELECT DISTINCT [month]
, COUNT (transaction_id) OVER ( PARTITION BY [month] ) AS number_trans_month -- Đếm số giao dịch của từng tháng
FROM table_month

-- Sau đó tính tỷ trọng giao dịch của mỗi tháng so với cả năm là bao nhiêu % ?


WITH table_month AS (
SELECT transaction_time, transaction_id
, MONTH (transaction_time) AS [month]
FROM fact_transaction_2019 AS fact_19
JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
WHERE category = 'Telco'
)
, count_month AS (
SELECT DISTINCT [month]
, COUNT (transaction_id) OVER ( PARTITION BY [month] ) AS number_trans_month -- Đếm số giao dịch của từng tháng
FROM table_month
)
SELECT *
, ( SELECT COUNT (transaction_id) FROM table_month ) AS total_trans -- Subquery
, SUM (number_trans_month) OVER ( ) AS total_trans -- Tính tổng bằng Window Function
, FORMAT ( number_trans_month *1.0 / SUM (number_trans_month) OVER ( ) , 'p' ) AS pct
FROM count_month


-- Tính số tiền của từng ngày và cả tháng trong năm 2019 (telco)


SELECT DISTINCT
MONTH (transaction_time) AS [month], DAY (transaction_time) AS [day]
, SUM (charged_amount) OVER ( PARTITION BY MONTH (transaction_time) ) AS amount_month
, SUM (charged_amount) OVER ( PARTITION BY MONTH (transaction_time), DAY (transaction_time) ) AS amount_day
FROM fact_transaction_2019 AS fact_19
JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
WHERE category = 'Telco'
ORDER BY [month], [day]


-- 3 kh chi nhiều tiền nhất mỗi tháng
WITH table_month AS (
    SELECT customer_id
        , transaction_id
        , charged_amount
    , MONTH (transaction_time) AS [month]
    , SUM (charged_amount) OVER ( PARTITION BY MONTH (transaction_time), customer_id)AS amount_cus
    FROM fact_transaction_2019 AS fact_19
    JOIN dim_scenario AS scena
    ON fact_19.scenario_id = scena.scenario_id
    WHERE category = 'Telco'
)
SELECT distinct customer_id
    
FROM table_month
ORDER BY month, customer_id

-- ex 3: Hãy tìm ra top 3 KH chi nhiều tiền nhất trong mỗi tháng (2019 Telco)


-- Chữa:


with sum_cus_amount as (
SELECT DISTINCT MONTH(transaction_time) as [month]
, customer_id
, SUM(charged_amount) OVER ( PARTITION BY MONTH(transaction_time), customer_id) as total_amount
FROM fact_transaction_2019 as fact_19
JOIN dim_scenario as sce
ON fact_19.scenario_id = sce.scenario_id
WHERE category = 'Telco'
)
, rank_table AS (
SELECT *
, RANK() OVER ( PARTITION BY [month] ORDER BY total_amount DESC ) as ranking
FROM sum_cus_amount
)
SELECT *
FROM rank_table
WHERE ranking < 4
ORDER BY [month], ranking


-- 3. Tính tích lũy (cộng dồn giá trị)

WITH count_month AS (
SELECT DISTINCT
MONTH (transaction_time) AS [month]
, COUNT (transaction_id) OVER ( PARTITION BY MONTH (transaction_time) ) AS number_trans
FROM fact_transaction_2019 AS fact_19
JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
WHERE category = 'Telco'
-- ORDER BY [month]
)
SELECT *
, SUM (number_trans) OVER ( ORDER BY [month] ASC ) AS accummulating_trans
FROM count_month



-- Tính tỷ tăng trưởng số KH trong 2020 so với 2019 theo tháng

WITH count_month AS (
SELECT YEAR (transaction_time) AS [year]
, MONTH (transaction_time) AS [month]
, COUNT (DISTINCT customer_id) AS number_customers_current_year
FROM (
SELECT * FROM fact_transaction_2019
UNION
SELECT *
FROM fact_transaction_2020 ) AS fact_table
JOIN dim_scenario AS scena
ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Telco'
GROUP BY YEAR (transaction_time) , MONTH (transaction_time)
-- ORDER BY [year], [month]
)
SELECT *
, LAG (number_customers_current_year, 12) OVER ( ORDER BY [year], [month] ) AS number_customers_last_year
, FORMAT ( ( number_customers_current_year - LAG (number_customers_current_year, 12) OVER ( ORDER BY [year], [month] ) ) *1.0 /
LAG (number_customers_current_year, 12) OVER ( ORDER BY [year], [month] ) , 'p') AS growth
FROM count_month

--> Tính tổng nhiều đối tượng
--> Xếp hạng
--> Tích lũy
--> Xử lý phức tạp: LAG (column, N) OVER () : lấy giá trị dòng trên xuống dòng hiện tại


--- LEAD (column, N) OVER () : lấy giá trị dòng dưới mang lên dòng hiện tại




-- success trans năm 2019 của khách hàng telco
with success_trans as (
    SELECT distinct customer_id
        , YEAR (transaction_time) AS [year]
        , COUNT (transaction_id) OVER ( PARTITION BY customer_id, YEAR (transaction_time) ) AS number_trans
    FROM fact_transaction_2019 AS fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
    JOIN dim_scenario AS scena
        ON fact_table.scenario_id = scena.scenario_id
    WHERE category = 'Telco'
    AND status_description = 'success'
    ORDER BY customer_id
)