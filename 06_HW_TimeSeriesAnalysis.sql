-- 1. GROUP BY
-- When we need to group together data lines of the same nature and calculate the SUM, COUNT, MIN,
-- MAX, AVG commands.
-- Task 1: Calculate the number of successful transactions of each month in 2019
-- --Your code here

SELECT MONTH (transaction_time) AS [month]
, COUNT (transaction_id ) AS number_success_trans
FROM fact_transaction_2019 AS fact_19
JOIN dim_status AS stt
ON fact_19.status_id = stt.status_id
WHERE status_description = 'success'
GROUP BY MONTH (transaction_time)
ORDER BY [month]

-- Task 2.1: Calculate the number of successful transactions of each month in 2019 and 2020 (using Group
-- By). Then create a column of the total number of successful transactions of each year (using Window
-- Function). Finally calculate the successful transaction rate (success_rate) of each month.

WITH success_trans AS (
    SELECT YEAR (transaction_time) AS [year]
        , MONTH (transaction_time) AS [month]
        , COUNT (transaction_id ) AS number_success_trans
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT *
        FROM fact_transaction_2020 ) AS fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
    WHERE status_description = 'success'

    GROUP BY YEAR (transaction_time) , MONTH (transaction_time)

)

-- , 
SELECT *
    , SUM (number_success_trans) OVER(PARTITION BY year) AS number_success_trans_year
    , FORMAT(number_success_trans * 1.0 / SUM (number_success_trans) OVER(PARTITION BY year), 'p') AS pct

FROM success_trans


-- Task 2.2: Find out the TOP 3 months with the most failed transactions of each year (using window
-- function)

WITH fail_trans AS (
    SELECT DISTINCT YEAR (transaction_time) AS [year]
        , MONTH (transaction_time) AS [month]
        , COUNT (transaction_id) OVER ( PARTITION BY YEAR (transaction_time), MONTH (transaction_time) ) AS number_trans_month 
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT *
        FROM fact_transaction_2020 ) AS fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
    WHERE status_description != 'success'
)

, rank_table AS (
SELECT *
, RANK() OVER (PARTITION BY year ORDER BY number_trans_month DESC ) as ranking
FROM fail_trans
)


SELECT *
FROM rank_table
WHERE ranking < 4
ORDER BY [year], ranking


-- Task 2.3 : Calculate the average distance between successful payments per customer in Telecom group
-- 2019.


WITH success_trans AS (
    SELECT customer_id
        , transaction_id
        , transaction_time
        , LAG (transaction_time) OVER (PARTITION BY customer_id ORDER BY transaction_time) AS last_trans_time
    FROM fact_transaction_2019 AS fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
    JOIN dim_scenario AS scena
        ON fact_table.scenario_id = scena.scenario_id
    WHERE category = 'Telco'
    AND status_description = 'success'
)

, day_dist AS (
    SELECT *
        , DATEDIFF(day, last_trans_time, transaction_time) AS day_distance

    FROM success_trans
)

SELECT DISTINCT customer_id
    , AVG(day_distance) OVER (PARTITION BY customer_id) AS avg_gap_day
FROM day_dist


--

--- PART 2: SQL APPLIED TO REAL PROBLEMS ---
-- 1. TREND
-- 1.1
SELECT DISTINCT YEAR (transaction_time) AS [year]
    , MONTH (transaction_time) AS [month]
    , CONVERT(nvarchar(6), transaction_time, 112) AS time_calendar 
    , COUNT (transaction_id ) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time)) AS number_success_trans
FROM (
    SELECT * FROM fact_transaction_2019
    UNION
    SELECT *
    FROM fact_transaction_2020 ) AS fact_table
JOIN dim_status AS stt
    ON fact_table.status_id = stt.status_id
JOIN dim_scenario AS scena
    ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing'
AND status_description = 'success'

ORDER BY [year], [month]

-- 1.2. Comparing Component
-- Task A: You know that there are many sub-categories of the Billing group. After reviewing the above
-- result, you should break down the trend into each sub-categories.

SELECT DISTINCT YEAR (transaction_time) AS [year]
    , MONTH (transaction_time) AS [month]
    , sub_category
    , COUNT (transaction_id ) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time), sub_category) AS number_success_trans
FROM (
    SELECT * FROM fact_transaction_2019
    UNION
    SELECT *
    FROM fact_transaction_2020 ) AS fact_table
JOIN dim_status AS stt
    ON fact_table.status_id = stt.status_id
JOIN dim_scenario AS scena
    ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing'
AND status_description = 'success'

ORDER BY [year], [month]


-- Task B: Then modify the result as the following table: Only select the sub-categories belong to list
-- (Electricity, Internet and Water)

-- PIVOT TABLE

SELECT DISTINCT YEAR (transaction_time) AS [year]
    , MONTH (transaction_time) AS [month]
    , COUNT (CASE WHEN sub_category = 'Electricity' THEN transaction_id END) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time)) AS electricity_trans
    , COUNT (CASE WHEN sub_category = 'Internet' THEN transaction_id END) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time)) AS internet_trans
    , COUNT (CASE WHEN sub_category = 'Water' THEN transaction_id END) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time)) AS water_trans
FROM (
    SELECT * FROM fact_transaction_2019
    UNION
    SELECT *
    FROM fact_transaction_2020 ) AS fact_table
JOIN dim_status AS stt
    ON fact_table.status_id = stt.status_id
JOIN dim_scenario AS scena
    ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing'
AND status_description = 'success'
ORDER BY [year], [month]


-- 1.3. Percent of Total Calculations:
-- Task: Based on the previous query, you need to calculate the proportion of each sub-category
-- (Electricity, Internet and Water) in the total for each month. Let’s see the desired outcome:

WITH category_trans AS (
    SELECT DISTINCT YEAR (transaction_time) AS [year]
        , MONTH (transaction_time) AS [month]
        , COUNT (CASE WHEN sub_category = 'Electricity' THEN transaction_id END) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time)) AS electricity_trans
        , COUNT (CASE WHEN sub_category = 'Internet' THEN transaction_id END) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time)) AS internet_trans
        , COUNT (CASE WHEN sub_category = 'Water' THEN transaction_id END) OVER(PARTITION BY YEAR (transaction_time) , MONTH (transaction_time)) AS water_trans
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT *
        FROM fact_transaction_2020 ) AS fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
    JOIN dim_scenario AS scena
        ON fact_table.scenario_id = scena.scenario_id
    WHERE category = 'Billing'
    AND status_description = 'success'
)

SELECT *
    , (electricity_trans + water_trans + internet_trans) AS total_trans
    , FORMAT(electricity_trans * 1.0 / (electricity_trans + water_trans + internet_trans), 'p') AS elec_pct
    , FORMAT(internet_trans * 1.0 / (electricity_trans + water_trans + internet_trans), 'p') AS internet_pct
    , FORMAT(water_trans * 1.0 / (electricity_trans + water_trans + internet_trans), 'p') AS water_pct
FROM category_trans
    ORDER BY [year], [month]


---


-- 1.4 Hãy cho biết số lượng giao dịch thanh toán tiền điện theo mỗi tuần (từ 2019 --> 2020), chỉ tính giao dịch thành công

    SELECT DISTINCT YEAR (transaction_time) AS [year]
        , DATEPART(wk, transaction_time) AS [week]
        , COUNT (transaction_id) OVER(PARTITION BY YEAR (transaction_time) ,  DATEPART(wk, transaction_time)) AS electricity_trans
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT *
        FROM fact_transaction_2020 ) AS fact_table
    JOIN dim_status AS stt
        ON fact_table.status_id = stt.status_id
    JOIN dim_scenario AS scena
        ON fact_table.scenario_id = scena.scenario_id
    WHERE sub_category = 'Electricity'
    AND status_description = 'success'
    ORDER BY year, week

--- 1.4 B Hãy show ra chỉ số: số lượng giao dịch của 4 tuần gần nhất ( từ kết quả bài 1.4 A )


WITH count_elec AS (
    SELECT YEAR(transaction_time) as [year]
        , DATEPART(week, transaction_time) as [week]
        , COUNT(transaction_id ) as electricity_trans
    FROM (
        SELECT * FROM fact_transaction_2019
        UNION
        SELECT * FROM fact_transaction_2020
    ) as fact_table
    JOIN dim_scenario as sce
        ON fact_table.scenario_id = sce.scenario_id
    JOIN dim_status as stt
        ON fact_table.status_id = stt.status_id
    WHERE sub_category = 'Electricity'
        AND status_description = 'Success'
    GROUP BY YEAR(transaction_time), DATEPART(week, transaction_time)
)
SELECT *
, AVG (electricity_trans) OVER ( ORDER BY [year], [week]
ROWS BETWEEN 3 PRECEDING AND CURRENT ROW ) AS avg_last_4_weeks
FROM count_elec

--> Strategy muốn review xem mình có nên thy đổi hạn mức 24h chuyển được 100M?
-- tính theo khoảng tgian cuốn chiếu 24h,48h,72h.... 
---> khoảng tgian k quy được ra số dòng: phải dùng hàm RANGE (hiện tại T-sql chưa deploy?)

-- https://learn.microsoft.com/en-us/sql/t-sql/queries/select-over-clause-transact-sql?view=sql-server-ver16