-- 1.1. Retrieve a report that includes the following information: customer_id, transaction_id,
-- scenario_id, transaction_type, sub_category, category and status_description. These
-- transactions must meet the following conditions:
-- ● Were created in Jan 2020
-- ● Status is successful


SELECT customer_id
    , transaction_id
    , fact_20.scenario_id
    , transaction_type
    , sub_category
    , category
    , status_description

FROM fact_transaction_2020 AS fact_20
JOIN dim_scenario
    ON fact_20.scenario_id = dim_scenario.scenario_id
JOIN dim_status
    ON fact_20.status_id = dim_status.status_id

WHERE MONTH(transaction_time) = 1
    AND status_description = 'Success'

-- 1.2. Calculate Success Rate of each transaction_type

WITH join_transaction AS 
(
    SELECT customer_id
        , transaction_id
        , fact_20.scenario_id
        , transaction_type
        , sub_category
        , category
        , status_description

    FROM fact_transaction_2020 AS fact_20
    JOIN dim_scenario
        ON fact_20.scenario_id = dim_scenario.scenario_id
    JOIN dim_status
        ON fact_20.status_id = dim_status.status_id

    WHERE MONTH(transaction_time) = 1
)

, nb_trans_t AS 
(
    SELECT DISTINCT transaction_type
        , COUNT (transaction_id) OVER(PARTITION BY transaction_type) AS nb_trans 
        , COUNT (CASE WHEN status_description = 'Success' THEN transaction_id END) OVER(PARTITION BY transaction_type) AS nb_success_trans
    FROM join_transaction
)

SELECT *
    , nb_success_trans * 1.0 / nb_trans AS success_rate

FROM nb_trans_t
ORDER BY nb_trans DESC