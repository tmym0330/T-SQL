-- SIMPLE QUERY

SELECT 'Toi ten la MTM' T,
'Toi ten la THN' H

-- Data từ bảng
SELECT *
FROM SalesLT.Customer

-- bảng có bao nhiêu dòng
SELECT COUNT(*)
FROM SalesLT.Customer

-- 
SELECT CustomerID
, NameStyle
FROM SalesLT.Customer

-- 2/ Sắp xếp kết quả hiển thị
SELECT CustomerID
, NameStyle
, LastName
, CompanyName
FROM SalesLT.Customer
ORDER BY LastName ASC, CustomerID DESC

-- 3. Chọn lọc dòng để hiển thị

SELECT CustomerID
, NameStyle
, LastName
, CompanyName
FROM SalesLT.Customer
WHERE CustomerID < 1000
ORDER BY CustomerID DESC

-- Alternate operators
SELECT *
FROM SalesLT.Product
WHERE Color='Black' AND ListPrice > 1000

--> 25 sp

SELECT *
FROM SalesLT.Product
WHERE SellStartDate BETWEEN '2005-01-01' AND '2006-12-31'
-- lẩy từ 00:00 01-01-05 đến 00:00 31-12-06, muốn lấy cả ngày thì phải đổi thành 00:00 01-01-07

-- IN ()

-- LIKE (gần giống)

SELECT *
FROM SalesLT.Product
WHERE Name LIKE '%Road%'

SELECT *
FROM SalesLT.Product
WHERE Name LIKE 'HL%'

-- min 15 kí tự
SELECT *
FROM SalesLT.Product
WHERE Name LIKE 'HL_____________%'

-- bắt đầu bằng HL, kí tự thứ 4 khác R

SELECT *
FROM SalesLT.Product
WHERE Name LIKE 'HL_[^R]%'

-- bắt đầu bằng HL, kí tự thứ 4 từ A -> M
SELECT *
FROM SalesLT.Product
WHERE Name LIKE 'HL_[A-M]%'

-- bắt đầu bằng HL, kí tự thứ 4 từ A -> M
SELECT *
FROM SalesLT.Product
WHERE Name LIKE 'HL_[BCM]%'

-- bắt đầu bằng HL, kí tự thứ 4 từ A -> M
SELECT *
FROM SalesLT.Product
WHERE Name LIKE 'HL_[B,C,M]%' AND ProductNumber Like '%[7-9]'
--

SELECT *
FROM SalesLT.Product
WHERE Name LIKE 'HL_[^BCM]%' 

---

SELECT Top 5 *
FROM SalesLT.Product
WHERE Name LIKE 'HL_[^BCM]%' 
--
SELECT DISTINCT Color
FROM SalesLT.Product

SELECT Color
FROM SalesLT.Product