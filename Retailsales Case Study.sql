--Checking if on any given day there was no unit sold
SELECT*FROM retailsales_case1;
--WHERE NOT date  IN('30/12/2013','31/12/2013');
--WHERE cost_of_sales = 0 OR sales = 0 OR quantity_sold = 0;


--Converting date from text to date format
SELECT
    CAST(date AS DATE) AS Date,
FROM retailsales_case1;


--Counting the number of records
SELECT COUNT(*) FROM retailsales_case1;


--Daily sales price per unit
SELECT Date,
    sales/quantity_sold AS Sales_per_unit_price
FROM retailsales_case1;


--Average selling price per unit
SELECT AVG(sales/quantity_sold) AS Selling_price_per_Unit
FROM retailsales_case1;


--Daily percentage gross profit
SELECT Date,
    ((sales-cost_of_sales)/sales)*100 AS Percent_Daily_Gross_Profit
FROM retailsales_case1;


--Daily percentage gross profit per unit
SELECT Date,
    ((sales/quantity_sold-cost_of_sales/quantity_sold)/(sales/quantity_sold))*100 AS Percentage_Daily_Gross_Profit_per_unit,
FROM RETAILSALES_CASE1;


--Periods in which the product was on promotion
-- SELECT date,
--     quantity_sold,
--     sales
-- FROM retailsales_case1
-- ORDER BY QUANTITY_SOLD DESC
-- LIMIT 3;

-- SELECT MAX(sales) AS maximum_sales,
--     MIN(sales) AS minimum_sales,
--     AVG(sales) Average_sales
-- FROM RETAILSALES_CASE1;

--Determining the average daily sales and quantity sold
WITH Average_Data AS ( 
            SELECT 
                AVG(sales) AS Average_Daily_Sales,
                ROUND(AVG(quantity_sold),0) AS Average_Daily_Quantity_Sold,
                AVG(((sales-cost_of_sales)/sales)*100) AS Ave_Percent_Gross_Profit,
            FROM retailsales_case1
)

--Identifying dates with sales or quantities significantly higher than the average
SELECT
    date,
    cost_of_sales,
    sales/quantity_sold AS Sales_per_unit_price,
    sales,
    quantity_sold,
    ((sales-cost_of_sales)/sales)*100 AS Percent_Daily_Gross_Profit,
    CASE
        WHEN sales > (SELECT Average_Daily_Sales*2.5 FROM AVERAGE_DATA) THEN 'Promotion'
        WHEN quantity_sold > (SELECT Average_Daily_Quantity_Sold*2.5 FROM AVERAGE_DATA) THEN 'Promotion'
        ELSE 'Regular'
    END AS sales_type
FROM retailsales_case1
WHERE sales_type = 'Promotion'
ORDER BY quantity_sold DESC
LIMIT 3;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--GETTING MONTH ON MONTH GROWTH

-- Aggregate daily records into monthly totals, including the year

WITH monthly_data AS(
    SELECT 
        TRUNC(date, 'MONTH') AS month,   --Returns first day of the month the sale was made
        YEAR(date) AS year,
        SUM(sales) AS total_sales,
        SUM(cost_of_sales) AS total_cost_of_sales,
        SUM(quantity_sold) AS total_quantity_sold
    FROM retailsales_case1
    GROUP BY month, year
    ORDER BY year, month
)

--Compute the month on month growth
SELECT 
    month,
    year,
        total_sales,
    LAG(total_sales) OVER (ORDER BY year, month) AS previous_month_sales,
        ((total_sales - LAG(total_sales) OVER (ORDER BY year, month)) / LAG(total_sales) OVER (ORDER BY year, month)) * 100 AS sales_mom_growth,
    LAG(total_cost_of_sales) OVER (ORDER BY year, month) AS previous_month_cost_of_sales,
        ((total_cost_of_sales - LAG(total_cost_of_sales) OVER (ORDER BY year, month)) / LAG(total_cost_of_sales) OVER (ORDER BY year, month)) * 100 AS cost_of_sales_mom_growth,
    LAG(total_quantity_sold) OVER (ORDER BY year, month) AS previous_quantity_sold,
        ((total_quantity_sold - LAG(total_quantity_sold) OVER (ORDER BY year, month)) / LAG(total_quantity_sold) OVER (ORDER BY year, month)) * 100 AS quantity_sold_mom_growth
FROM monthly_data;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--GETTING YEAR ON YEAR GROWTH

-- Aggregate daily records into yearly totals

WITH yearly_data AS(
    SELECT
        YEAR(date) AS year,
        SUM(sales) AS total_sales,
        SUM(cost_of_sales) AS total_cost_of_sales,
        SUM(quantity_sold) AS total_quantity_sold
    FROM retailsales_case1
    GROUP BY year
    ORDER BY year
)

--Compute the month on month growth
SELECT 
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year) AS previous_year_sales,
    ((total_sales - LAG(total_sales) OVER (ORDER BY year)) / LAG(total_sales) OVER (ORDER BY year)) * 100 AS sales_yoy_growth,
    LAG(total_cost_of_sales) OVER (ORDER BY year) AS previous_year_cost_of_sales,
    ((total_cost_of_sales - LAG(total_cost_of_sales) OVER (ORDER BY year)) / LAG(total_cost_of_sales) OVER (ORDER BY year)) * 100 AS cost_of_sales_yoy_growth,
    LAG(total_quantity_sold) OVER (ORDER BY year) AS previous_year_quantity_sold,
    ((total_quantity_sold - LAG(total_quantity_sold) OVER (ORDER BY year)) / LAG(total_quantity_sold) OVER (ORDER BY year)) * 100 AS quantity_sold_yoy_growth
FROM yearly_data;
























