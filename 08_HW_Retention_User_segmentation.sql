-- PART 2: Cohort Analysis &amp; User Segmentation

-- Task A
WITH join_table AS (
    SELECT transaction_id
        , customer_id
        , transaction_time 
    FROM fact_transaction_2019 as fact_19

    JOIN dim_scenario AS sce
    ON fact_19.scenario_id = sce.scenario_id

    WHERE sub_category = 'Telco Card'
    AND status_id = 1
)

-- base month: 1 (Jan)

SELECT MONTH(transaction_time) - 1 AS subsequent_month
    , COUNT (DISTINCT customer_id) AS number_users
FROM join_table
WHERE customer_id in (SELECT DISTINCT customer_id
    FROM join_table
    WHERE MONTH(transaction_time) =  1)

GROUP BY MONTH(transaction_time);

-- TASK B
WITH join_table AS (
    SELECT transaction_id
        , customer_id
        , transaction_time 
    FROM fact_transaction_2019 as fact_19

    JOIN dim_scenario AS sce
    ON fact_19.scenario_id = sce.scenario_id

    WHERE sub_category = 'Telco Card'
    AND status_id = 1
)


, retain_users AS (
    SELECT MONTH(transaction_time) - 1 AS subsequent_month
        , COUNT (DISTINCT customer_id) AS retained_users
    FROM join_table
    WHERE customer_id in (SELECT DISTINCT customer_id
        FROM join_table
        WHERE MONTH(transaction_time) =  1)

    GROUP BY MONTH(transaction_time)
)

SELECT *
    , (SELECT COUNT (DISTINCT customer_id) FROM join_table WHERE MONTH(transaction_time) =  1) AS original_users
    , FORMAT(retained_users * 1.0/ (SELECT COUNT (DISTINCT customer_id) FROM join_table WHERE MONTH(transaction_time) =  1), 'p') AS pct
FROM retain_users


-- 1.2. Cohorts Derived from the Time Series Itself
-- Task A: Expand your previous query to calculate retention for multi attributes from the acquisition
-- month (first month) (from Jan to December).

-- TASK B
WITH join_table AS (
    SELECT transaction_id
        , customer_id
        , transaction_time 
        , MIN(transaction_time) OVER(PARTITION BY customer_id) AS acquisition_time
    FROM fact_transaction_2019 as fact_19

    JOIN dim_scenario AS sce
    ON fact_19.scenario_id = sce.scenario_id

    WHERE sub_category = 'Telco Card'
    AND status_id = 1
)


, total_table AS (
    SELECT MONTH(acquisition_time) AS acquisition_month
        , DATEDIFF(month, acquisition_time, transaction_time) AS subsequent_month
        , *
    FROM join_table

)

, retain_users AS (
    SELECT acquisition_month
        , subsequent_month
        , COUNT (DISTINCT customer_id) AS retained_users
    FROM total_table

    GROUP BY acquisition_month
        , subsequent_month
)

SELECT *
    , (SELECT COUNT (DISTINCT customer_id) FROM join_table WHERE MONTH(acquisition_time) =  acquisition_month) AS original_users
    , FORMAT(retained_users * 1.0/ (SELECT COUNT (DISTINCT customer_id) FROM join_table WHERE MONTH(acquisition_time) =  acquisition_month), 'p') AS pct
FROM retain_users
ORDER BY acquisition_month


-- Task B: Then modify the result as the following table:

-- lỗi

-- WITH join_table AS (
--     SELECT transaction_id
--         , customer_id
--         , transaction_time 
--         , MIN(transaction_time) OVER(PARTITION BY customer_id) AS acquisition_time
--     FROM fact_transaction_2019 as fact_19

--     JOIN dim_scenario AS sce
--     ON fact_19.scenario_id = sce.scenario_id

--     WHERE sub_category = 'Telco Card'
--     AND status_id = 1
-- )


-- , total_table AS (
--     SELECT MONTH(acquisition_time) AS acquisition_month
--         , DATEDIFF(month, acquisition_time, transaction_time) AS subsequent_month
--         , *
--     FROM join_table

-- )

-- , retain_users AS (
--     SELECT acquisition_month
--         , subsequent_month
--         , COUNT (DISTINCT customer_id) AS retained_users
--     FROM total_table

--     GROUP BY acquisition_month
--         , subsequent_month
-- )


-- SELECT acquisition_month,  
--     [0], [1], [2], [3], [4],[5], [6], [7], [8], [9], [10], [11]
-- FROM  
--     (SELECT *
--         , (SELECT COUNT (DISTINCT customer_id) FROM join_table WHERE MONTH(acquisition_time) =  acquisition_month) AS original_users
--         , FORMAT(retained_users * 1.0/ (SELECT COUNT (DISTINCT customer_id) FROM join_table WHERE MONTH(acquisition_time) =  acquisition_month), 'p') AS pct
--     FROM retain_users
--     ORDER BY acquisition_month)   
--     AS source_t  
-- PIVOT  
-- (  
--     (pct)
-- FOR subsequent_month  IN ( [0], [1], [2], [3], [4],[5], [6], [7], [8], [9], [10], [11])  
-- ) AS destinstion
-- ORDER BY clause;


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

SELECT customer_id
    , SUM(charged_amount) AS Monetary
    , COUNT (DISTINCT trans_date) AS Frequency
    , DATEDIFF(day, CONVERT(DATE, MAX(trans_date)),'2020-12-31') AS Recency
FROM join_table
GROUP BY customer_id