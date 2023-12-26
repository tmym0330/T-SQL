-- 1.1.
SELECT DISTINCT City, StateProvince
FROM SalesLT.Address
ORDER BY StateProvince ASC, City DESC

-- 1.2.
SELECT TOP 10 PERCENT Name, Weight
FROM SalesLT.Product
ORDER BY Weight DESC


-- 2.1.
SELECT ProductID, Name
FROM SalesLT.Product
WHERE Color IN ('Black','Red','White') 
AND Size in ('S', 'M')


-- 2.2.
SELECT ProductID, ProductNumber, Name
FROM SalesLT.Product
WHERE 
(Color IN ('Black','Red','White') 
OR Size in ('S', 'M'))
AND
ProductNumber Like 'BK-[^T]%-[0-9][0-9]'


-- 2.3.

SELECT ProductID, ProductNumber, Name, ListPrice
FROM SalesLT.Product
WHERE 
ProductNumber Like '________%' -- AND LEN(ProductNumber) >= 8
AND (Name LIKE ('%HL%')
OR Name LIKE '%Mountain%')
AND ProductID NOT IN (SELECT DISTINCT ProductID FROM SalesLT.SalesOrderDetail)


---> Đi tìm những sp đã order
SELECT DISTINCT ProductID FROM SalesLT.SalesOrderDetail

--> 142 sp đã ordered --> 153 chưa ordered

-- [Name]: Khai báo đây là column name (không trùng với lệnh T-SQL)

