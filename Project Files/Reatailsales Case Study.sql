-- DATA WRANGLING

SELECT*FROM brightlight.public.retailsales
LIMIT 10;

-- Covering date to the correct format
SELECT
    TO_DATE(date,'DD/MM/YYYY')
FROM brightlight.public.retailsales
LIMIT 10;


-- Checking the number of records
SELECT COUNT(*) FROM brightlight.public.retailsales;


-- Checking for completely duplicates rows
SELECT *,
    COUNT(*)
FROM brightlight.public.retailsales
GROUP BY ALL
HAVING COUNT(*) > 1;

-- Checking for missing values
SELECT*FROM brightlight.public.retailsales
WHERE date IS NULL OR SALES IS NULL OR cost_of_sales IS NULL OR quantity_sold IS NULL;

-- Creating a temporary table with the corrected date format
CREATE OR REPLACE TEMP TABLE retailsales_new AS (
    SELECT 
        TO_DATE(date,'DD/MM/YYYY') AS date,
        sales,
        cost_of_sales,
        quantity_sold
    FROM brightlight.public.retailsales
);

SELECT * FROM retailsales_new;

--------------------------------------------------------------------------------------------------------------------------------------

-- Determining Average metrics
CREATE OR REPLACE TEMP TABLE average_data AS (
    SELECT 
        AVG(sales) AS Average_Daily_Sales,
        ROUND(AVG(quantity_sold),0) AS Average_Daily_Quantity_Sold,
        AVG(((sales-cost_of_sales)/sales)*100) AS Ave_Percent_Gross_Profit,
    FROM retailsales_new
);

SELECT * FROM average_data;


-- Determining sales per unit price, daily %gross profit, daily %gross profit per unit, daily sale type (Promotion or Regular)
CREATE OR REPLACE TEMP TABLE retailsales_new AS (
SELECT Date,
    YEAR(date) AS year,
    MONTHNAME(date) AS month_name,
    TO_CHAR(date, 'MON yyyy') AS MonthYear,
    sales,
    cost_of_sales,
    quantity_sold,
    sales/quantity_sold AS Sales_per_unit_price,
    ((sales-cost_of_sales)/sales) AS Fraction_Daily_Gross_Profit,
    ((sales/quantity_sold-cost_of_sales/quantity_sold)/(sales/quantity_sold)) AS Fraction_Daily_Gross_Profit_per_unit,
    CASE
        WHEN sales > (SELECT Average_Daily_Sales*2.5 FROM average_data) THEN 'Promotion'
        WHEN quantity_sold > (SELECT Average_Daily_Quantity_Sold*2.5 FROM average_data) THEN 'Promotion'
        ELSE 'Regular'
    END AS sales_type
FROM retailsales_new
);


-- MONTH ON MONTH GROWTH

-- Aggregrate daily records into monthly totals
WITH monthly_data AS (
    SELECT
        TRUNC(date, 'MONTH') AS month,          -- Returns the first day of the month of the sale
        YEAR(date) AS year,
        SUM(sales) AS total_sales,
        SUM(cost_of_sales) AS total_cost_of_sales,
        SUM(quantity_sold) AS total_quantity_sold
    FROM retailsales_new
    GROUP BY ALL
    ORDER BY year, month
)

-- Determine the month on month growth
SELECT
    month,
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year, month) AS previous_month_sales,
    ((total_sales - LAG(total_sales) OVER (ORDER BY year, month)) / LAG(total_sales) OVER (ORDER BY year, month)) AS sales_mom_growth,
    LAG(total_cost_of_sales) OVER (ORDER BY year, month) AS previous_month_cost_of_sales,
    ((total_cost_of_sales - LAG(total_cost_of_sales) OVER (ORDER BY year, month)) / LAG(total_cost_of_sales) OVER (ORDER BY year, month)) AS cost_of_sales_mom_growth,
    LAG(total_quantity_sold) OVER (ORDER BY year, month) AS previous_quantity_sold,
    ((total_quantity_sold - LAG(total_quantity_sold) OVER (ORDER BY year, month)) / LAG(total_quantity_sold) OVER (ORDER BY year, month)) AS quantity_sold_mom_growth
FROM monthly_data;



-- YEAR ON YEAR GROWTH

-- Aggregrate daily records into yearlt totals
WITH yearly_data AS (
    SELECT
        YEAR(date) AS year,
        SUM(sales) AS total_sales,
        SUM(cost_of_sales) AS total_cost_of_sales,
        SUM(quantity_sold) AS total_quantity_sold
    FROM retailsales_new
    GROUP BY ALL
    ORDER BY year
)

-- determine year on year growth
SELECT 
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year) AS previous_year_sales,
    ((total_sales - LAG(total_sales) OVER (ORDER BY year)) / LAG(total_sales) OVER (ORDER BY year)) AS sales_yoy_growth,
    LAG(total_cost_of_sales) OVER (ORDER BY year) AS previous_year_cost_of_sales,
    ((total_cost_of_sales - LAG(total_cost_of_sales) OVER (ORDER BY year)) / LAG(total_cost_of_sales) OVER (ORDER BY year)) AS cost_of_sales_yoy_growth,
    LAG(total_quantity_sold) OVER (ORDER BY year) AS previous_year_quantity_sold,
    ((total_quantity_sold - LAG(total_quantity_sold) OVER (ORDER BY year)) / LAG(total_quantity_sold) OVER (ORDER BY year)) AS quantity_sold_yoy_growth
FROM yearly_data;


-- PED

-- Determining Price Elasticity of Demand during promotion
WITH monthly_agg AS (
  SELECT
    TRUNC(date, 'MONTH') AS month,          -- Returns the first day of the month of the sale
    YEAR(date) AS year,
    SALES_TYPE,
    AVG(SALES_PER_UNIT_PRICE) AS avg_price,
    AVG(QUANTITY_SOLD) AS avg_quantity
  FROM retailsales_new
  GROUP BY ALL
),

pivoted AS (
    SELECT
        year,
        month,
            MAX(CASE WHEN SALES_TYPE = 'Promotion' THEN avg_price END) AS promo_price,
            MAX(CASE WHEN SALES_TYPE = 'Regular' THEN avg_price END) AS regular_price,
            MAX(CASE WHEN SALES_TYPE = 'Promotion' THEN avg_quantity END) AS promo_quantity,
            MAX(CASE WHEN SALES_TYPE = 'Regular' THEN avg_quantity END) AS regular_quantity
      FROM monthly_agg
      GROUP BY ALL
)

SELECT
    year, month,
  ((promo_quantity - regular_quantity) / NULLIF(regular_quantity, 0.0)) /
  ((promo_price - regular_price) / NULLIF(regular_price, 0.0)) AS price_elasticity
FROM pivoted
WHERE promo_price IS NOT NULL AND regular_price IS NOT NULL;






















