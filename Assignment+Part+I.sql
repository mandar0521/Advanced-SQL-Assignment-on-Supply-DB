use supply_db ;


/*
Question : Golf related products

List all products in categories related to golf. Display the Product_Id, Product_Name in the output. Sort the output in the order of product id.
Hint: You can identify a Golf category by the name of the category that contains golf.

*/
SELECT Product_Name,
       Product_Id
FROM   product_info p
       JOIN category c
         ON c.Id = p.Category_Id
WHERE  Lower(c.name) LIKE '%golf%'
ORDER  BY product_id;

-- **********************************************************************************************************************************

/*
Question : Most sold golf products

Find the top 10 most sold products (based on sales) in categories related to golf. Display the Product_Name and Sales column in the output. Sort the output in the descending order of sales.
Hint: You can identify a Golf category by the name of the category that contains golf.

HINT:
Use orders, ordered_items, product_info, and category tables from the Supply chain dataset.
*/
SELECT pi.Product_Name,
       Sum(oi.sales) AS Sales
FROM   orders ord
       LEFT JOIN ordered_items oi
              ON ord.Order_Id = oi.Order_Id
       LEFT JOIN product_info pi
              ON pi.Product_Id = oi.Item_Id
       LEFT JOIN category ct
              ON ct.Id = pi.Category_Id
WHERE  Lower(ct.name) LIKE '%golf%'
GROUP  BY pi.Product_Name
ORDER  BY Sales DESC
LIMIT 10; 
-- **********************************************************************************************************************************


/*
Question: Segment wise orders

Find the number of orders by each customer segment for orders. Sort the result from the highest to the lowest 
number of orders.The output table should have the following information:
-Customer_segment
-Orders


*/
SELECT ci.Segment AS Customer_Segment,
       Count(ord.order_id) AS Orders
FROM   customer_info ci
       LEFT JOIN orders ord
              ON ord.customer_id = ci.id
GROUP  BY Customer_Segment
ORDER  BY Orders DESC; 

-- **********************************************************************************************************************************

/*
Question : Percentage of order split

Description: Find the percentage of split of orders by each customer segment for orders that took six days 
to ship (based on Real_Shipping_Days). Sort the result from the highest to the lowest percentage of split orders,
rounding off to one decimal place. The output table should have the following information:
-Customer_segment
-Percentage_order_split

HINT:
Use the orders and customer_info tables from the Supply chain dataset.


*/
WITH Ord_Summary
AS
  (
            SELECT    ci.Segment AS Customer_Segment,
                      round(count(ord.Order_Id),1) AS Orders
            FROM      customer_info ci
            LEFT JOIN orders ord
            ON        ord.Customer_Id = ci.Id
            WHERE     ord.Real_Shipping_Days = 6
            GROUP BY  Customer_Segment )
  SELECT   a.Customer_Segment,
           round((a.Orders / sum(b.Orders))*100,1) AS Percentage_Order_Split
  FROM     Ord_Summary a
  JOIN     Ord_Summary b
  GROUP BY Customer_Segment
  ORDER BY Percentage_Order_Split DESC;

-- **********************************************************************************************************************************
