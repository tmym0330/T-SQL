--Subquery
-- WHERE (): như hwork 3 optional

-- FROM () -> tạo 1 bảng phụ, từ đó mình làm tiếp bước nữa

-- b1: gộp data 2019,20
-- b2: join với scenario lấy giao dịch tiền điện

SELECT *
FROM

-- Ở SELECT (): subquery sẽ tính ra 1 thông tin (cột mới/bảng mới) -> hiển thị ra

--> Subquery chỉ được trả về 1 giá trị mà thôi --> tính tổng: max, min, sum, count, avg

SELECT TOP 5 customer_id, charged_amount
    , (SELECT max(charged_amount) FROM fact_transaction_2020) as max_val_2020
    , (SELECT max(charged_amount) FROM fact_transaction_2019) as max_val_2019
FROM fact_transaction_2019



-- #
-- Groupby:

-- 1: cho biết mỗi khách hàng đang phát sinh bao nhiêu giao dịch (thành công) trong 2-19
-- nhóm hóa đơn điện

SELECT customer_id
    , count(transaction_id) as number_of_transactions
FROM fact_transaction_2019 as fact_2019 
lEFT JOIN dim_scenario as sce
ON fact_2019.scenario_id = sce.scenario_id
lEFT JOIN dim_status as sta 
ON fact_2019.status_id = sta.status_id
WHERE status_description = 'success' AND sub_category = 'Electricity'
GROUP BY customer_id
ORDER BY number_of_transactions DESC

-- thêm tổng số tiền, số category

SELECT customer_id
, COUNT (transaction_id) AS number_of_trans
, SUM (charged_amount) AS total_amount
, COUNT (DISTINCT category) AS number_of_categories  -- đếm không trùng
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta
ON fact_19.status_id = sta.status_id
WHERE status_description = 'success' AND sub_category = 'Electricity'
GROUP BY customer_id
ORDER BY number_of_trans DESC

-- count: đếm số dòng

select *
from fact_transaction_2019

-- 3: mỗi tháng có bn khách hàng bao nhiêu giao dịch trong 2019 của hóa đơn điện

-- 1 dùng subquery


SELECT [month]
, COUNT ( DISTINCT customer_id ) AS number_of_customers
, COUNT ( transaction_id) AS number_of_trans
FROM (
SELECT MONTH (transaction_time) AS [month]
, transaction_id
, customer_id
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta
ON fact_19.status_id = sta.status_id
WHERE status_description = 'success' AND sub_category = 'Electricity'
) AS fact_table
GROUP BY [month]
ORDER BY [month]   

-- 2: Dùng CTE để tạo bảng tạm

WITH fact_tab as (
    SELECT MONTH (transaction_time) AS [month]
    , transaction_id
    , customer_id
    FROM fact_transaction_2019 AS fact_19
    LEFT JOIN dim_scenario AS scena
    ON fact_19.scenario_id = scena.scenario_id
    LEFT JOIN dim_status AS sta
    ON fact_19.status_id = sta.status_id
    WHERE status_description = 'success' AND sub_category = 'Electricity'
)


SELECT [month]
, COUNT ( DISTINCT customer_id ) AS number_of_customers
, COUNT ( transaction_id) AS number_of_trans
FROM fact_tab
GROUP BY [month]
ORDER BY [month]   


-- Nhiệm vụ của CTE --> tạo ra các bảng tạm để lưu kết quả từng bước xử lý lại


--> Gặp bài phức tạm : b1, b2, b3, b4, b5 --> Mỗi bước mn xử lý xong sẽ lưu vào 1 CTE


--> Chúng ta có quyền tạo nhiều CTE trong 1 câu truy vấn


WITH fact_table AS ( -- bước 1 : JOIN và tạo thêm cột MONTH
SELECT MONTH (transaction_time) AS [month]
, transaction_id
, customer_id
, platform_id
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena
ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta
ON fact_19.status_id = sta.status_id
WHERE status_description = 'success' AND sub_category = 'Electricity'
)
, table_plat AS ( -- b2: JOIN bảng platform
SELECT fact_table.*, payment_platform
FROM fact_table
LEFT JOIN dim_platform AS plat
ON fact_table.platform_id = plat.platform_id
)
SELECT [month], payment_platform -- b3: GROUP BY month và payment_platform
, COUNT ( DISTINCT customer_id ) AS number_of_customers
, COUNT ( transaction_id) AS number_of_trans
FROM table_plat
GROUP BY [month], payment_platform
ORDER BY [month]



SELECT *
FROM dbo.fact_transaction_2019  --396 817


SELECT *
FROM dbo.dim_payment_channel


SELECT *
FROM dbo.dim_platform

SELECT *
FROM dbo.dim_scenario 