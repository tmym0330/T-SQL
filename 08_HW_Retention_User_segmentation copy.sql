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

SELECT MONTH(transaction_time) as month
    , MONTH(transaction_time) - 1 AS subsequent_month
    , COUNT (DISTINCT customer_id) OVER(PARTITION BY MONTH(transaction_time)) AS retained_users
    -- , COUNT (DISTINCT customer_id) AS retained_users
FROM join_table
WHERE customer_id in (SELECT DISTINCT customer_id
    FROM join_table
    WHERE MONTH(transaction_time) =  1)
-- GROUP BY MONTH(transaction_time)