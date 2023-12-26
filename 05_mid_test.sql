-- 2.1
SELECT customer_id
    , transaction_id   
    , sce.scenario_id
    , transaction_type
    , sub_category
    , category
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario AS sce
    ON sce.scenario_id = fact_19.scenario_id
WHERE MONTH(fact_19.transaction_time) = 2
        AND transaction_type IS NOT NULL

SELECT *
FROM fact_transaction_2019 as fact_19
SELECT *
FROM dim_status

-- 2.2
SELECT TOP 10 PERCENT customer_id
    , transaction_id  
    , charged_amount 
FROM fact_transaction_2019 as fact_19
LEFT JOIN dim_scenario AS sce
    ON sce.scenario_id = fact_19.scenario_id
LEFT JOIN dim_status as stt 
    ON stt.status_id = fact_19.status_id
WHERE MONTH(fact_19.transaction_time) = 2
    AND transaction_type = 'Payment'
    AND status_description = 'Payment failed'
ORDER BY charged_amount DESC 

-- 3.1.
SELECT TOP 10 customer_id
    , COUNT(transaction_id) AS number_trans
    , COUNT (DISTINCT fact_20.scenario_id) AS number_scenarios
    , COUNT (DISTINCT sce.category) AS number_categories
    , SUM(charged_amount) AS total_amount
FROM fact_transaction_2020 as fact_20
LEFT JOIN dim_scenario AS sce
    ON sce.scenario_id = fact_20.scenario_id
LEFT JOIN dim_status as stt 
    ON stt.status_id = fact_20.status_id
WHERE MONTH(transaction_time) IN (1,2,3)
    AND status_description = 'Success'
    AND transaction_type = 'Payment'
GROUP BY customer_id

ORDER BY SUM(charged_amount) DESC

-- 3.2
-- a
WITH join_table AS 
    (SELECT customer_id
        , COUNT(transaction_id) AS number_trans
        , COUNT (DISTINCT fact_20.scenario_id) AS number_scenarios
        , COUNT (DISTINCT sce.category) AS number_categories
        , SUM(charged_amount) AS total_amount
    FROM fact_transaction_2020 as fact_20
    LEFT JOIN dim_scenario AS sce
        ON sce.scenario_id = fact_20.scenario_id
    LEFT JOIN dim_status as stt 
        ON stt.status_id = fact_20.status_id
    WHERE MONTH(transaction_time) IN (1,2,3)
        AND status_description = 'Success'
        AND transaction_type = 'Payment'
    GROUP BY customer_id
)
, total_table AS
(
    SELECT customer_id
        , total_amount
        , (SELECT AVG(CAST(total_amount AS numeric)) FROM join_table) AS avg_amount
    FROM join_table
)

SELECT *
    , CASE WHEN total_amount > avg_amount THEN 'greater_than_avg'
    ELSE 'lower_than_avg'
    END 
    AS group_customer
FROM total_table

-- b

WITH join_table AS 
    (SELECT customer_id
        , COUNT(transaction_id) AS number_trans
        , COUNT (DISTINCT fact_20.scenario_id) AS number_scenarios
        , COUNT (DISTINCT sce.category) AS number_categories
        , SUM(charged_amount) AS total_amount
    FROM fact_transaction_2020 as fact_20
    LEFT JOIN dim_scenario AS sce
        ON sce.scenario_id = fact_20.scenario_id
    LEFT JOIN dim_status as stt 
        ON stt.status_id = fact_20.status_id
    WHERE MONTH(transaction_time) IN (1,2,3)
        AND status_description = 'Success'
        AND transaction_type = 'Payment'
    GROUP BY customer_id
)
, total_table AS
(
    SELECT customer_id
        , total_amount
        , (SELECT AVG(CAST(total_amount AS numeric)) FROM join_table) AS avg_amount
    FROM join_table
)

, group_table AS (
    SELECT *
        , CASE WHEN total_amount > avg_amount THEN 'greater_than_avg'
        ELSE 'lower_than_avg'
        END 
        AS group_customer
    FROM total_table
)
, count_table AS (
    SELECT group_customer
        , COUNT(group_customer) AS number_in_group
        , (SELECT COUNT(customer_id) FROM group_table) AS total_count
        
    FROM group_table 
    GROUP BY group_customer
)
SELECT *   
    , FORMAT(number_in_group * 1.0/ total_count, 'p') AS percent_group
FROM count_table
WHERE group_customer = 'greater_than_avg'
