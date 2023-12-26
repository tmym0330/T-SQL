
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


-- 1.4 Hãy cho biết số lượng giao dịch thanh toán tiền điện theo mỗi tuần (từ 2019 --> 2020), chỉ tính giao dịch thành công

    SELECT DISTINCT YEAR (transaction_time) AS [year]
        , DATEPART(wk, transaction_time) AS [week]
        , COUNT (CASE WHEN sub_category = 'Electricity' THEN transaction_id END) OVER(PARTITION BY YEAR (transaction_time) ,  DATEPART(wk, transaction_time)) AS electricity_trans
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