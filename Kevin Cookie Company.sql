USE kcc;
select * from kcc.kcc_ordered_products_db;
select * from kcc.kcc_orders_db;
select * from kcc.kcc_products_list_db;
select * from kcc.kcc_customer_db;
Drop Table kcc.kcc_orders_db;

-- How many products are there?
SELECT 
    COUNT(CookieID)
FROM
    kcc_products_list_db;

-- Which are the top selling Cookie?
SELECT 
    pl.CookieName, COUNT(op.Quantity) AS Ordered_Quantity
FROM
    kcc_ordered_products_db op
        RIGHT JOIN
    kcc_products_list_db pl ON op.CookieID = pl.CookieID
GROUP BY pl.CookieName
ORDER BY Ordered_Quantity DESC;

-- Total sold cookies by quantity:
SELECT 
    pl.CookieName, SUM(op.Quantity) AS Total_Ordered_Quantity
FROM
    kcc_ordered_products_db op
        RIGHT JOIN
    kcc_products_list_db pl ON op.CookieID = pl.CookieID
GROUP BY pl.CookieName
ORDER BY Total_Ordered_Quantity DESC;

-- Fortune Cookie is sold the most quantity, what is the profit on each Fortune cookie?
SELECT 
    CookieName,
    SUM(RevenuePerCookie) - SUM(CostPerCookie) AS Profit_Per_Unit
FROM
    kcc_products_list_db
WHERE
    CookieName = (SELECT 
            CookieName
        FROM
            (SELECT 
                pl.CookieName, SUM(op.Quantity) AS Total_Ordered_Quantity
            FROM
                kcc_ordered_products_db op
            RIGHT JOIN kcc_products_list_db pl ON op.CookieID = pl.CookieID
            GROUP BY pl.CookieName
            ORDER BY Total_Ordered_Quantity DESC
            LIMIT 1) AS a)
GROUP BY CookieName;

-- cookie names, Month and sold Quantity 
SELECT 
    CookieName, MONTHNAME(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS Month, SUM(Quantity) Total_Quantity
FROM
    kcc_orders_db o
        JOIN
    kcc_ordered_products_db op ON o.OrderID = op.OrderID
        RIGHT JOIN
    kcc_products_list_db pl ON pl.CookieID = op.CookieID
GROUP BY MONTHNAME(STR_TO_DATE(OrderDate, '%d-%m-%Y')), pl.CookieName
ORDER BY Total_Quantity DESC;

-- Month wise Total quantity sold

SELECT 
    MONTHNAME(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS Month, SUM(Quantity) Total_Quantity
FROM
    kcc_orders_db o
        JOIN
    kcc_ordered_products_db op ON o.OrderID = op.OrderID
        RIGHT JOIN
    kcc_products_list_db pl ON pl.CookieID = op.CookieID
GROUP BY MONTHNAME(STR_TO_DATE(OrderDate, '%d-%m-%Y'))
ORDER BY Total_Quantity DESC;

-- 1st Date and the last date of the business -- 1st Jan 2022 to 14th March 2022

SELECT 
    STR_TO_DATE(OrderDate, '%d-%m-%Y') AS 1Date
FROM
    kcc_orders_db
    ORDER BY 1Date DESC;
SELECT 
    STR_TO_DATE(OrderDate, '%d-%m-%Y') AS 1Date
FROM
    kcc_orders_db
    ORDER BY 1Date;
    
-- Total revenue, product wise for the month of Jan
       
SELECT pl.CookieName, SUM(p.Quantity*pl.RevenuePerCookie) AS Total_Revenue, monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS Order_Month
FROM kcc_ordered_products_db p
JOIN kcc_products_list_db pl ON pl.CookieID=p.CookieID
JOIN kcc_orders_db o ON p.OrderID=o.OrderID
WHERE monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) = 'January'
group by pl.CookieName, monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y'));

-- Total revenue, product wise & Month wise
SELECT pl.CookieName, SUM(p.Quantity*pl.RevenuePerCookie) AS Total_Revenue, monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS Order_Month
FROM kcc_ordered_products_db p
JOIN kcc_products_list_db pl ON pl.CookieID=p.CookieID
JOIN kcc_orders_db o ON p.OrderID=o.OrderID
WHERE monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) IN (SELECT monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) FROM kcc_orders_db)
group by pl.CookieName, monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y'));

-- Slight different with the same query:
SELECT pl.CookieName, monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) AS Order_Month, SUM(p.Quantity*pl.RevenuePerCookie) AS Total_Revenue
FROM kcc_ordered_products_db p
JOIN kcc_products_list_db pl ON pl.CookieID=p.CookieID
JOIN kcc_orders_db o ON p.OrderID=o.OrderID
WHERE monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) IN (SELECT monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y')) FROM kcc_orders_db)
group by pl.CookieName, monthname(STR_TO_DATE(OrderDate, '%d-%m-%Y'))
ORDER BY pl.CookieName, Order_Month;

-- Create a view where CustermerId, Customer name, Count of total numbers of Orders & Total Order Value  

CREATE OR REPLACE VIEW Business_Summary AS
    (SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(op.OrderID) AS Count_of_Orders,
        SUM(op.Quantity) AS Total_Quantity,
        SUM(op.Quantity) / COUNT(op.OrderID) AS Quantity_per_Order,
        SUM(pl.RevenuePerCookie * op.Quantity) AS Total_Order_Value,
        SUM(pl.RevenuePerCookie * op.Quantity) / SUM(op.Quantity) AS Value_per_order
    FROM
        kcc_customer_db c
            LEFT JOIN
        kcc_orders_db o ON o.CustomerID = c.CustomerID
            LEFT JOIN
        kcc_ordered_products_db op ON op.OrderID = o.OrderID
            LEFT JOIN
        kcc_products_list_db pl ON pl.CookieID = op.CookieID
    GROUP BY c.CustomerID , c.CustomerName);
SELECT * FROM business_summary;

-- SELECT c.CustomerID, c.CustomerName, count(op.OrderID) AS Count_of_Orders, SUM(op.Quantity) AS Total_Quantity, SUM(op.Quantity)/count(op.OrderID) AS Quantity_per_Order,SUM(pl.RevenuePerCookie)*SUM(op.Quantity) AS Total_Order_Value, SUM(pl.RevenuePerCookie)*SUM(op.Quantity)/SUM(op.Quantity) AS Value_per_order FROM kcc_customer_db c LEFT JOIN kcc_orders_db o ON o.CustomerID=c.CustomerID LEFT JOIN kcc_ordered_products_db op ON op.OrderID=o.OrderID LEFT JOIN kcc_products_list_db pl ON pl.CookieID=op.CookieID GROUP BY c.CustomerID, c.CustomerName;

-- Create view that shows Business Summary till date monthly
CREATE OR REPLACE VIEW Business_Summary_Month_wise AS
 (SELECT 
        c.CustomerID,
        c.CustomerName,
        monthname(STR_TO_DATE(o.OrderDate, '%d-%m-%Y')) AS Month,
        COUNT(op.OrderID) AS Count_of_Orders,
        SUM(op.Quantity) AS Total_Quantity,
        SUM(op.Quantity) / COUNT(op.OrderID) AS Quantity_per_Order,
        SUM(pl.RevenuePerCookie * op.Quantity) AS Total_Order_Value,
        SUM(pl.RevenuePerCookie * op.Quantity) / SUM(op.Quantity) AS Value_per_order
        
    FROM
        kcc_customer_db c
            LEFT JOIN
        kcc_orders_db o ON o.CustomerID = c.CustomerID
            LEFT JOIN
        kcc_ordered_products_db op ON op.OrderID = o.OrderID
            LEFT JOIN
        kcc_products_list_db pl ON pl.CookieID = op.CookieID
    GROUP BY c.CustomerID , c.CustomerName, monthname(STR_TO_DATE(o.OrderDate, '%d-%m-%Y'))
    ORDER BY Month);
SELECT * FROM business_summary_month_wise;

-- Create views summary of Cookie wise Total cost, revenue and profit of the business Monthly
CREATE OR REPLACE VIEW Cookie_wise_Monthly_summary AS
 (SELECT 
        pl.CookieID,
        pl.CookieName,
        monthname(STR_TO_DATE(o.OrderDate, '%d-%m-%Y')) AS Month,
        pl.RevenuePerCookie,
        pl.CostPerCookie,
        -- COUNT(op.OrderID) AS Count_of_Orders,
        SUM(op.Quantity) AS Total_Quantity,
        SUM(pl.RevenuePerCookie * op.Quantity) AS Revenue,
        SUM(pl.CostPerCookie * op.Quantity) AS Cost,
        SUM(pl.RevenuePerCookie * op.Quantity) - SUM(pl.CostPerCookie * op.Quantity) AS Profit
        -- SUM(op.Quantity) / COUNT(op.OrderID) AS Quantity_per_Order,
        -- SUM(pl.RevenuePerCookie * op.Quantity) / SUM(op.Quantity) AS Average_Revenue_per_cookie
        
    FROM
        kcc_customer_db c
            LEFT JOIN
        kcc_orders_db o ON o.CustomerID = c.CustomerID
            LEFT JOIN
        kcc_ordered_products_db op ON op.OrderID = o.OrderID
            LEFT JOIN
        kcc_products_list_db pl ON pl.CookieID = op.CookieID
    GROUP BY pl.CookieID, pl.CookieName, monthname(STR_TO_DATE(o.OrderDate, '%d-%m-%Y')), pl.RevenuePerCookie, pl.CostPerCookie
    ORDER BY pl.CookieID);
    
    SELECT * FROM Cookie_wise_Monthly_summary;

-- Create a view summary of Cookie wise Total cost, revenue and profit of the business YTD:

CREATE OR REPLACE VIEW Cookie_wise_YTD_summary AS
 (SELECT 
        pl.CookieID,
        pl.CookieName,
        pl.RevenuePerCookie,
        pl.CostPerCookie,
        -- COUNT(op.OrderID) AS Count_of_Orders,
        SUM(op.Quantity) AS Total_Quantity,
        SUM(pl.RevenuePerCookie * op.Quantity) AS Revenue,
        SUM(pl.CostPerCookie * op.Quantity) AS Cost,
        SUM(pl.RevenuePerCookie * op.Quantity) - SUM(pl.CostPerCookie * op.Quantity) AS Profit
        -- SUM(op.Quantity) / COUNT(op.OrderID) AS Quantity_per_Order,
        -- SUM(pl.RevenuePerCookie * op.Quantity) / SUM(op.Quantity) AS Average_Revenue_per_cookie
	FROM
        kcc_customer_db c
            LEFT JOIN
        kcc_orders_db o ON o.CustomerID = c.CustomerID
            LEFT JOIN
        kcc_ordered_products_db op ON op.OrderID = o.OrderID
            LEFT JOIN
        kcc_products_list_db pl ON pl.CookieID = op.CookieID
    GROUP BY pl.CookieID, pl.CookieName, pl.RevenuePerCookie, pl.CostPerCookie
    ORDER BY pl.CookieID);
    
    SELECT * FROM Cookie_wise_YTD_summary;

-- Rank the Cookies based on their Profits:
 
SELECT CookieName, Profit, RANK() OVER(ORDER BY Profit Desc) AS Profit_rank
FROM cookie_wise_ytd_summary
WHERE CookieName IS NOT NULL AND Profit IS NOT NULL;

-- Rank the best month based on their profits for each cookie creating a window:
SELECT 
ROW_NUMBER() OVER(PARTITION BY Month) AS rn, 
CookieID, 
CookieName, 
Month, 
Profit, 
RANK() OVER(partition by CookieName ORDER BY Profit Desc) AS Profit_rank,
MAX(Revenue) OVER(partition by CookieName) AS Max_Revenue,
MAX(Profit) OVER(partition by CookieName) AS Max_Profit,
SUM(Profit) OVER(partition by CookieName) AS Total_Profit_Cookie_wise
FROM cookie_wise_monthly_summary
WHERE CookieName IS NOT NULL AND Profit IS NOT NULL;

-- Stored proceedure for matrix that contains total sales sumary for the day:

DELIMITER $$ 
CREATE PROCEDURE Sales ()
BEGIN
SELECT op.OrderID, count(distinct(op.CookieID)) as count, SUM(pl.RevenuePerCookie*op.Quantity) as Rev
FROM kcc_ordered_products_db op JOIN kcc_orders_db o 
ON o.OrderID=op.OrderID JOIN kcc_products_list_db pl
ON pl.CookieID=op.CookieID
GROUP BY op.OrderID;
END$$
DELIMITER ;

CALL kcc.Sales();

-- A procedure where the store operator can check the cookie profit, revenue and percentage profit by inputing a cookie id at a time:

DELIMITER $$ 
CREATE PROCEDURE Cookie_wise_Rev_Cost_Profit_PercentageProfit (IN C_ID INT)
BEGIN 
SELECT CookieID, CookieName, Revenue, Cost, Profit, sum(Profit) / sum(Revenue) * 100 as Percentage_Profit
FROM Cookie_wise_YTD_summary 
WHERE CookieID=C_ID
GROUP BY CookieID, CookieName;
END$$
DELIMITER ;

-- If the store operator wants to know the details about a particular customer with the customer ID then the below procedure:

DELIMITER $$ 
CREATE PROCEDURE Cust_Details (IN Cust_ID INT)
BEGIN 
SELECT *
FROM kcc_customer_db 
WHERE CustomerID=Cust_ID;
END$$
DELIMITER ;
