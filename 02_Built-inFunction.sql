
-- 1.1 Retrieve customer names and phone numbers
-- Each customer has an assigned salesperson. You must write a query to create a call sheet that lists:
-- The salesperson
-- A column named CustomerName that displays how the customer contact should be greeted (for example, Mr Smith)
-- The customer’s phone number.

SELECT CONCAT_WS(' ', SUBSTRING (Title,  1, LEN(Title) - 1), FirstName) AS title_name
    , SUBSTRING (SalesPerson,  CHARINDEX ('\', SalesPerson) + 1, LEN(SalesPerson) - CHARINDEX ('\', SalesPerson) ) AS sales_person_name
    , Phone
FROM SalesLT.Customer

-- Có null ở title


-- 1.2 Retrieve the heaviest products information
-- Transportation costs are increasing and you need to identify the heaviest products. Retrieve the names, weight of the top ten percent of products by weight. 
-- Then, add new column named Number of sell days (caculated from SellStartDate and SellEndDate) of these products (if sell end date isn't defined then get Today date) 

SELECT TOP 10 PERCENT Name
    , Weight 
    , DATEDIFF(day, SellStartDate, isnull(SellEndDate, GETDATE()) ) AS number_of_sell_days
FROM SalesLT.Product
ORDER BY Weight DESC

-- 1.3. Retrieve the information: 
--         Get the second word in the Product Name column (words separated by spaces).

SELECT ProductID
    , SUBSTRING([Name]
        , CHARINDEX(' ', Name) + 1
        , CASE WHEN CHARINDEX(' ', Name, CHARINDEX(' ', Name) + 1) - CHARINDEX(' ', Name) - 1 > 0 
        THEN CHARINDEX(' ', Name, CHARINDEX(' ', Name) + 1) - CHARINDEX(' ', Name) - 1
        ELSE LEN(Name) - CHARINDEX(' ', Name)
        END)
    AS second_word    
FROM SalesLT.Product
ORDER BY ProductID 


-- select * FROM SalesLT.Product
-- ORDER BY ProductID


-- Task 2: Retrieve customer order data 
 
-- 2.1 As you continue to work with the Adventure Works customer data, you must create queries for reports that have been requested by the sales team.
-- Retrieve a list of customer companies
-- You have been asked to provide a list of all customer companies in the format Customer ID : Company Name - for example, 78: Preferred Bikes

SELECT CONCAT(CustomerID, ': ', CompanyName) AS customer_company
FROM SalesLT.Customer

 
-- 2.2 Retrieve a list of sales order revisions
-- The SalesLT.SalesOrderHeader table contains records of sales orders. You have been asked to retrieve data for a report that shows:
-- The sales order number and revision number in the format () – for example SO71774 (2).
-- The order date converted to ANSI standard 102 format (yyyy.mm.dd – for example 2015.01.31).

SELECT CONCAT(SalesOrderNumber, ' (', RevisionNumber, ')') AS sales_order_revision
    , convert (varchar, OrderDate, 102) as new_format_date
FROM SalesLT.SalesOrderHeader


-- Task 3: Retrieve customer contact details (hard) 

-- 3.1 Some records in the database include missing or unknown values that are returned as NULL. You must create some queries that handle these NULL values appropriately.
-- Retrieve customer contact names with middle names if known
-- You have been asked to write a query that returns a list of customer names. 
-- The list must consist of a single column in the format first last (for example Keith Harris) if the middle name is unknown, or first middle last (for example Jane M. Gates) if a middle name is known.
 
SELECT CASE WHEN MiddleName IS NULL THEN CONCAT_WS(' ', FirstName, LastName)
    ELSE CONCAT_WS(' ', FirstName, MiddleName, LastName)
    END
    AS full_name
FROM SalesLT.Customer
 
-- 3.2 Retrieve primary contact details
-- Customers may provide Adventure Works with an email address, a phone number, or both. 
-- If an email address is available, then it should be used as the primary contact method; if not, then the phone number should be used. 
-- You must write a query that returns a list of customer IDs in one column, and a second column named PrimaryContact that contains the email address if known, 
-- and otherwise the phone number.
-- "

SELECT CustomerID
    , CASE WHEN EmailAddress IS NOT NULL THEN EmailAddress
    ELSE Phone
    END
    AS primary_contact
FROM SalesLT.Customer

-- 3.3 As you continue to work with the Adventure Works customer, product and sales data, you must create queries for reports that have been requested by the sales team.
-- Retrieve a list of customers with no address
-- A sales employee has noticed that Adventure Works does not have address information for all customers. You must write a query that returns a list of customer IDs, company names, contact names (first name and last name), and phone numbers for customers with no address stored in the database.

SELECT customerID
    , companyName
    , CONCAT_WS(' ', FirstName, LastName) AS contact_name
    , Phone
FROM SalesLT.Customer
WHERE CustomerID NOT IN 
    (SELECT DISTINCT CustomerID 
    FROM SalesLT.CustomerAddress)



-- OPTIONAL
-- 1.
SELECT ProductID
    , ISNULL(Name, 'None') AS product_name
    , ISNULL(Size, 'None') AS size
    , ISNULL(Weight, 0) AS weight
FROM SalesLT.Product
WHERE Name LIKE '%Mountain%'
AND SellStartDate >= '2005-07-01 00:00:00.000' and SellStartDate <= '2007-07-02 00:00:00.000'

select * from saleslt.product

-- 1.2
SELECT ProductID
    , Name
    , StandardCost
    , ListPrice
    , (ListPrice - StandardCost) AS Profit
FROM SalesLT.Product

-- 2.
-- Mỗi đơn hàng có thời gian giao hàng dự kiến và thời gian thực vận chuyển đến nơi.
--  Hãy tìm ra số ngày đơn hàng được hoàn thành trước hoặc trễ so với dự kiến bao lâu. 
--  Thông tin được chọn ra gồm mã đơn hàng; ngày dự kiến vận chuyển, ngày vận chuyển tới 
--  (Hiển thị hai khung thời gian này dưới dạng ‘DD/MM/YYYY’); số ngày hoàn thành trước hoặc trễ. 


SELECT SalesOrderID
    , CONVERT(varchar, DueDate, 103) AS DueDate
    , CONVERT(varchar, ShipDate, 103) AS ShipDate
    , CONVERT(varchar, DATEDIFF(day, ShipDate, DueDate), 103) AS DaysBeforeDue
FROM SalesLT.SalesOrderHeader

-- 3. Tìm ra những sản phẩm đã được bán với số lượng lớn hơn 2 trở lên trên mỗi hóa đơn, 
-- và loại sản phẩm của chúng thuộc nhóm Road Frames, Touring Frames.
-- Thông tin hiển thị là mã sản phẩm tên sản phẩm, kích thước, giá bán.

-- -- quantity > 2
-- SELECT DISTINCT ProductID, UnitPrice
-- from SalesLT.SalesOrderDetail
-- WHERE OrderQty > 2
-- ORDER BY ProductID DESC

-- -- Group: Road Frames, Touring Frames
-- SELECT ProductID
-- FROM SalesLT.Product
-- WHERE [Name] LIKE '%Road Frame%' OR [Name] LIKE '%Touring Frame%'

-- full
SELECT ProductID, Name, Size, ListPrice
FROM SalesLT.Product
WHERE ([Name] LIKE '%Road Frame%' OR [Name] LIKE '%Touring Frame%')
    AND ProductID IN (SELECT DISTINCT ProductID
        FROM SalesLT.SalesOrderDetail
        WHERE OrderQty > 2)
ORDER BY ProductID DESC