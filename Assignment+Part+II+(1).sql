
use supply_db ;

/*  Question: Month-wise NIKE sales

	Description:
		Find the combined month-wise sales and quantities sold for all the Nike products. 
        The months should be formatted as ‘YYYY-MM’ (for example, ‘2019-01’ for January 2019). 
        Sort the output based on the month column (from the oldest to newest). The output should have following columns :
			-Month
			-Quantities_sold
			-Sales
		HINT:
			Use orders, ordered_items, and product_info tables from the Supply chain dataset.
*/		

SELECT 
    DATE_FORMAT(o.Order_date, '%Y-%m') AS Month,
    SUM(oi.Quantity) AS Quantities_Sold,
    SUM(oi.Sales) AS Sales
FROM
    ordered_items oi
        LEFT JOIN
    orders o ON o.Order_Id = oi.Order_Id
        LEFT JOIN
    product_info pi ON pi.Product_id = oi.Item_Id
WHERE
    lower(pi.Product_Name) LIKE '%nike%'
GROUP BY Month
ORDER BY Month;

-- **********************************************************************************************************************************
/*

Question : Costliest products

Description: What are the top five costliest products in the catalogue? Provide the following information/details:
-Product_Id
-Product_Name
-Category_Name
-Department_Name
-Product_Price

Sort the result in the descending order of the Product_Price.

HINT:
Use product_info, category, and department tables from the Supply chain dataset.


*/
SELECT 
    pi.Product_ID,
    pi.Product_Name,
    ct.Name AS Category_Name,
    dp.Name AS Department_Name,
    pi.Product_Price
FROM
    product_info pi
        INNER JOIN
    category ct ON ct.id = pi.Category_id
        INNER JOIN
    department dp ON dp.id = pi.Department_id
ORDER BY pi.Product_Price DESC
LIMIT 5;
-- **********************************************************************************************************************************

/*

Question : Cash customers

Description: Identify the top 10 most ordered items based on sales from all the ‘CASH’ type orders. 
Provide the Product Name, Sales, and Distinct Order count for these items. Sort the table in descending
 order of Order counts and for the cases where the order count is the same, sort based on sales (highest to
 lowest) within that group.
 
HINT: Use orders, ordered_items, and product_info tables from the Supply chain dataset.


*/

SELECT 
    pi.Product_Name AS 'Product Name',
    SUM(oi.Sales) AS Sales,
    COUNT(DISTINCT oi.Order_Id) AS 'Distinct Order Count'
FROM
    product_info pi
        INNER JOIN
    ordered_items oi ON oi.Item_Id = pi.Product_Id
        INNER JOIN
    orders o ON o.Order_Id = oi.Order_Id
WHERE
    o.Type = 'Cash'
GROUP BY pi.Product_Name
ORDER BY COUNT(DISTINCT oi.Order_Id) DESC, oi.SALES DESC
LIMIT 10;


-- **********************************************************************************************************************************
/*
Question : Customers from texas

Obtain all the details from the Orders table (all columns) for customer orders in the state of Texas (TX),
whose street address contains the word ‘Plaza’ but not the word ‘Mountain’. The output should be sorted by the Order_Id.

HINT: Use orders and customer_info tables from the Supply chain dataset.

*/

SELECT 
    o.Order_Id,
    o.Type,
    o.Real_Shipping_Days,
    o.Scheduled_Shipping_Days,
    o.Customer_Id,
    o.Order_City,
    o.Order_Date,
    o.Order_Region,
    o.Order_State,
    o.Order_Status,
    o.Shipping_Mode
FROM
    orders o
        LEFT JOIN
    customer_info ci ON ci.Id = o.Customer_Id
WHERE
    ci.State = 'TX'
        AND ci.Street LIKE '%Plaza%'
        AND ci.Street NOT LIKE '%Mountain%'
ORDER BY o.Order_Id;


-- **********************************************************************************************************************************
/*
 
Question: Home office

For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging to
“Apparel” or “Outdoors” departments. Compute the total count of such orders. The final output should contain the 
following columns:
-Order_Count

*/
SELECT 
    COUNT(o.Order_Id) AS Order_Count
FROM
    orders o
        INNER JOIN
    customer_info ci ON ci.Id = o.Customer_Id
        INNER JOIN
    ordered_items oi ON oi.Order_Id = o.Order_Id
        INNER JOIN
    product_info pi ON pi.Product_Id = oi.Item_Id
        INNER JOIN
    department d ON d.Id = pi.Department_Id
WHERE
    ci.Segment = 'Home Office'
        AND d.Name in ('Apparel','Outdoors');

-- **********************************************************************************************************************************
/*

Question : Within state ranking
 
For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging
to “Apparel” or “Outdoors” departments. Compute the count of orders for all combinations of Order_State and Order_City. 
Rank each Order_City within each Order State based on the descending order of their order count (use dense_rank). 
The states should be ordered alphabetically, and Order_Cities within each state should be ordered based on their rank. 
If there is a clash in the city ranking, in such cases, it must be ordered alphabetically based on the city name. 
The final output should contain the following columns:
-Order_State
-Order_City
-Order_Count
-City_rank

HINT: Use orders, ordered_items, product_info, customer_info, and department tables from the Supply chain dataset.

*/

WITH summary
     AS (SELECT o.order_id,
                Count(o.order_id) AS Order_Count
         FROM   orders o
                INNER JOIN customer_info ci
                        ON ci.id = o.customer_id
                INNER JOIN ordered_items oi
                        ON oi.order_id = o.order_id
                INNER JOIN product_info pi
                        ON pi.product_id = oi.item_id
                INNER JOIN department d
                        ON d.id = pi.department_id
         WHERE  ci.segment = 'Home Office'
                AND d.NAME in ('Apparel','Outdoors')
         GROUP  BY o.order_city)
SELECT o.Order_State,
       o.Order_City,
       s.Order_Count,
       Dense_rank()
         OVER (
           partition BY o.Order_State
           ORDER BY o.Order_City ASC ) AS City_Rank
FROM   orders o
       INNER JOIN summary s
               ON o.Order_Id = s.Order_Id; 



-- **********************************************************************************************************************************
/*
Question : Underestimated orders

Rank (using row_number so that irrespective of the duplicates, so you obtain a unique ranking) the 
shipping mode for each year, based on the number of orders when the shipping days were underestimated 
(i.e., Scheduled_Shipping_Days < Real_Shipping_Days). The shipping mode with the highest orders that meet 
the required criteria should appear first. Consider only ‘COMPLETE’ and ‘CLOSED’ orders and those belonging to 
the customer segment: ‘Consumer’. The final output should contain the following columns:
-Shipping_Mode,
-Shipping_Underestimated_Order_Count,
-Shipping_Mode_Rank

HINT: Use orders and customer_info tables from the Supply chain dataset.


*/

SELECT o.Shipping_Mode,
       Count(o.Scheduled_Shipping_Days < Real_Shipping_Days)
       AS
       Shipping_Underestimated_Order_Count,
       ROW_NUMBER()
         OVER (PARTITION BY YEAR(o.Order_Date)
           ORDER BY Count(o.Scheduled_Shipping_Days < Real_Shipping_Days) DESC)
       AS
       Shipping_Mode_Rank
FROM   orders o
       INNER JOIN customer_info ci
               ON o.Customer_Id = ci.Id
WHERE  (o.Order_Status = 'Complete' or o.Order_Status = 'Closed')
       AND ci.Segment = 'Consumer'
GROUP BY o.Shipping_Mode, YEAR(o.Order_Date);

-- **********************************************************************************************************************************





