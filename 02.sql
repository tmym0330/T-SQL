SELECT CustomerID
, FirstName
, MiddleName
, LastName
, CONCAT(FirstName, MiddleName, LastName) AS FullName
, CONCAT_WS(' ', FirstName, MiddleName, LastName)
FROM SalesLT.Customer


-- Naming convention
-- Pascal:HoVaTen
-- Camel: HoVaTen
-- Snake: ho_va_ten

-- 2. Chuyen doi kieu du lieu
-- CAST(column AS new_data_type)
SELECT CustomerID
    , FirstName
    , MiddleName
    , LastName
    , FirstName + LastName --> ghép chuỗi
    -- , CONCAT_WS(' ', FirstName, MiddleName, LastName)
    -- , CustomerID + LastName
    , CAST(CustomerID AS varchar) + LastName AS ma_kh

FROM SalesLT.Customer

-- khong dung string -> int dc, chi dung nguoc lai

-- CONVERT (new_data_type, column, [stype])

SELECT CustomerID
    , modifieddate
    , convert (varchar, modifieddate) as new_format
    , convert (varchar, modifieddate, 101) as new_format_2
    , convert (varchar, modifieddate, 102) as new_format_3
FROM SalesLT.Customer

-- khong cong tru duoc

-- 3. Function xu ly data thoi gian
SELECT CustomerID
    , Modifieddate
    , year(Modifieddate) AS [year]
    , MONTH(Modifieddate) AS [month]
    , year(Modifieddate) AS [year]
    , DATEPART(week, modifieddate) AS week_number
    , year(Modifieddate) AS [year]
    , year(Modifieddate) AS [year]
    , DATEPART (week, Modifieddate) AS week_number
    , GETDATE () AS today
    , DATEADD (hour, 7, GETDATE() ) AS vn_time
    , DATEDIFF (year, Modifieddate, GETDATE () ) AS number_years
FROM SalesLT.Customer


-- 4. Functions


-- CHARINDEX ( 'letter', string, [starting position] ): tìm vị trí kí tự
-- SUBSTRING (string, starting , number of letters ): cắt chuỗi từ vị trí bất kì

SELECT CustomerID, CompanyName
, LEN (CompanyName) AS lenght
, LEFT (CompanyName, 5) AS l_5
, RIGHT (CompanyName, 5) AS r_5
, CHARINDEX ('b', CompanyName) AS b_position
, CHARINDEX ('b', CompanyName, CHARINDEX ('b', CompanyName) + 1 ) AS b_position_2
, SUBSTRING (CompanyName, 3, 4) AS new_string
, REPLACE (CompanyName, 'Bike', 'Car') AS new_name
FROM SalesLT.Customer



SELECT CustomerID, SalesPerson, 
SUBSTRING (SalesPerson,  CHARINDEX ('\', SalesPerson) + 1, LEN(SalesPerson) - CHARINDEX ('\', SalesPerson) )
FROM SalesLT.Customer

-- tach companyName thanh nhieu tu
SELECT CustomerID
    , CompanyName,
    SUBSTRING (CompanyName, 1,  CHARINDEX (' ', CompanyName) - 1) first_w
    , SUBSTRING (CompanyName, CHARINDEX (' ', CompanyName) + 1,  CHARINDEX (' ', CompanyName - CHARINDEX (' ', CompanyName)) sec_w
FROM SalesLT.Customer


-- 5. Logical statement : mệnh đề xây dựng logic (trường hợp)


CASE WHEN condition_1 THEN value_1
WHEN condition_2 THEN value_2
WHEN condition_3 THEN value_3
...
ELSE value_n
END


SELECT ProductID
    , ListPrice 
    , CASE WHEN ListPrice < 100 THEN N'thấp'
        WHEN ListPrice < 1000 THEN N'trung bình'
        ELSE 'cao'
        END AS price_segment 
FROM SalesLT.Product


-- lỗi font
-- điều kiện nào ở trên sẽ chạy trước (như if)



-- NULL: không có giá trị sẽ không apply các phép tính toán (ra Null)
SELECT *
FROM SalesLT.Customer
WHERE MiddleName is NULL

-- CASE WHEN: Nhiều trường hợp
-- 2 trường hợp thì nên dùng IFF(clause, value_1, value_2)