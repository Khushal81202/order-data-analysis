-- find top 10 highest reveue generating products 
SELECT product_id, SUM(sale_price) AS sales
FROM df_orders
GROUP BY product_id
ORDER BY sales DESC
LIMIT 10;

-- find top 5 highest selling products in each region
with cte as (
select region,product_id,sum(sale_price) as sales
from df_orders
group by region,product_id)
select * from (
select *
, row_number() over(partition by region order by sales desc) as rn
from cte) A
where rn<=5

-- find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
SELECT 
    order_month,
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
) AS subquery
GROUP BY order_month
ORDER BY order_month;

-- for each category which month had highest sales 
SELECT o.category, o.order_year_month, o.sales
FROM (
    SELECT 
        category,
        DATE_FORMAT(order_date, '%Y%m') AS order_year_month,
        SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY category, DATE_FORMAT(order_date, '%Y%m')
) AS o  -- 🔹 Added alias "o" for the subquery
WHERE (o.category, o.sales) IN (
    SELECT sub.category, MAX(sub.sales)  -- 🔹 Ensured alias reference in SELECT
    FROM (
        SELECT 
            category,
            DATE_FORMAT(order_date, '%Y%m') AS order_year_month,
            SUM(sale_price) AS sales
        FROM df_orders
        GROUP BY category, DATE_FORMAT(order_date, '%Y%m')
    ) AS sub  -- 🔹 Added alias "sub" for the inner subquery
    GROUP BY sub.category
);

-- which sub category had highest growth by profit in 2023 compare to 2022
WITH cte AS (
    SELECT sub_category, YEAR(order_date) AS order_year,
           SUM(sale_price) AS sales
    FROM df_orders
    GROUP BY sub_category, YEAR(order_date)
)
, cte2 AS (
    SELECT sub_category,
           SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
           SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
    FROM cte 
    GROUP BY sub_category
)
SELECT sub_category, 
       (sales_2023 - sales_2022) AS profit_growth
FROM cte2
ORDER BY profit_growth DESC
LIMIT 1; 
