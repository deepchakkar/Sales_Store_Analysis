CREATE TABLE sales_store(
	transaction_id VARCHAR(15),
	customer_id VARCHAR(15),
	customer_name VARCHAR(30),
	customer_age INT,
	gender VARCHAR(15),
	product_id VARCHAR(15),
	product_name VARCHAR(15),
	product_category VARCHAR(15),
	quantiy INT,
	prce FLOAT,
	payment_mode VARCHAR(15),
	purchase_date DATE,
	time_of_purchase TIME,
	status VARCHAR(15)
);

SELECT * FROM sales_store;

SET DATEFORMAT dmy
BULK INSERT sales_store
FROM 'C:\Users\deepc\Downloads\archive\Sales.csv'
	WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n'
		);


SELECT * FROM sales_store;

SELECT * INTO sales FROM sales_store;

SELECT * FROM SALES;


-- ===================================================
-- DATA CLEANING
-- ===================================================

-- STEP 1 - To check for duplicate

SELECT transaction_id, COUNT(*)
FROM sales
GROUP BY transaction_id
HAVING COUNT(transaction_id) > 1;

TXN240646
TXN342128
TXN855235
TXN981773

WITH CTE AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS Row_num
	FROM sales
)
DELETE FROM CTE
WHERE Row_num = 2;


--WITH CTE AS (
--	SELECT *,
--		ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id) AS Row_num
--	FROM sales
--)
--SELECT * FROM CTE
--WHERE  transaction_id IN ('TXN240646','TXN342128', 'TXN855235', 'TXN981773');


-- STEP 2 - Correction of Headers

SELECT * FROM sales

EXEC sp_rename'sales.quantiy','quantity','COLUMN'
EXEC sp_rename'sales.prce','price','COLUMN'


-- STEP 3 - To check the Datatype

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';


-- STEP 4 - To check for NULLS

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, 
    COUNT(*) AS NullCount 
    FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales 
    WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL', 
    ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'sales';

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;


-- Treating NULL Values
SELECT *
FROM sales 
WHERE transaction_id IS NULL
OR
customer_id IS NULL
OR
customer_name IS NULL
OR
customer_age IS NULL
OR
gender IS NULL
OR
product_id IS NULL
OR
product_name IS NULL
OR
product_category IS NULL
OR
quantity IS NULL
or
payment_mode is null
or
purchase_date is null
or 
status is null
or 
price is null;


DELETE FROM sales
WHERE transaction_id  IS NULL;


SELECT *
FROM sales
WHERE customer_name = 'Ehsaan Ram';

UPDATE sales
SET customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900';

SELECT *
FROM sales
WHERE customer_name = 'Damini Raju';

UPDATE sales
SET customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663';

SELECT *
FROM sales
WHERE customer_id = 'CUST1003';

UPDATE sales
SET customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
WHERE transaction_id = 'TXN432798';


-- STEP 5 - DATA CLEANING

SELECT * FROM sales;

SELECT DISTINCT gender
FROM sales;

UPDATE sales
SET gender = 'F'
WHERE gender = 'Female';

UPDATE sales
SET gender = 'M'
WHERE gender = 'Male';

SELECT DISTINCT payment_mode
FROM sales;

UPDATE sales
SET payment_mode = 'Credit Card'
WHERE payment_mode = 'CC';


-- ===============================================================================================================================
-- DATA ANALYSIS
-- ===============================================================================================================================

--🔥 1. What are the top 5 most selling products by quantity?

SELECT TOP 5  product_name, SUM(quantity)
FROM sales
WHERE status = 'delivered'
GROUP BY product_name
ORDER BY SUM(quantity) DESC

--Business Problem: We don't know which products are most in demand.
--Business Impact: Helps prioritize stock and boost sales through targeted promotions.

-- ===============================================================================================================================

--📉 2. Which products are most frequently cancelled?

SELECT TOP 5 product_name, COUNT(*) total_cancelled
FROM sales
WHERE status = 'cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC;

--Business Problem: Frequent cancellations affect revenue and customer trust.
--Business Impact: Identify poor-performing products to improve quality or remove from catalog.

-- ===============================================================================================================================

--🕒 3. What time of the day has the highest number of purchases?

SELECT
	CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END AS time_of_day,
	COUNT(*) AS total_orders
FROM sales
GROUP BY
	CASE
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
	END
ORDER BY total_orders DESC;

-- ------------------------------------------------------------------------------------------

SELECT 
	DATEPART(HOUR,time_of_purchase) AS Peak_time,
	COUNT(*) AS Total_orders
FROM sales
GROUP BY DATEPART(HOUR,time_of_purchase)
ORDER BY Total_orders DESC;

--Business Problem Solved: Find peak sales times.
--Business Impact: Optimize staffing, promotions, and server loads.

-- ===============================================================================================================================

--👥 4. Who are the top 5 highest spending customers?

SELECT TOP 5 customer_name, FORMAT(SUM(price*quantity), 'C0' , 'en-IN') AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY SUM(price*quantity) DESC;

--Business Problem Solved: Identify VIP customers.
--Business Impact: Personalized offers, loyalty rewards, and retention.

-- ===============================================================================================================================

--🛍️ 5. Which product categories generate the highest revenue?

SELECT product_category , FORMAT(SUM(price * quantity), 'C0','en-IN') as revenue
FROM sales
GROUP BY product_category
ORDER BY SUM(price * quantity) DESC;

--Business Problem Solved: Identify top-performing product categories.
--Business Impact: Refine product strategy, supply chain, and promotions.
--allowing the business to invest more in high-margin or high-demand categories.

-- ===============================================================================================================================

--🔄 6. What is the return/cancellation rate per product category?

-- cancellation rate per product category

SELECT product_category, FORMAT(COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0/COUNT(*), 'N3' )+ ' %' AS cancelled_percent
FROM sales
GROUP BY product_category
Order BY cancelled_percent DESC;

-- return rate per product category

SELECT product_category, Format(COUNT(CASE WHEN status = 'returned' THEN 1 END) * 100.0/COUNT(*), 'N3')+ ' %' AS return_percent
FROM sales
GROUP BY product_category
ORDER BY return_percent DESC;



--Business Problem Solved: Monitor dissatisfaction trends per category.
---Business Impact: Reduce returns, improve product descriptions/expectations.
--Helps identify and fix product or logistics issues.


-- ===============================================================================================================================


--💳 7. What is the most preferred payment mode?

SELECT payment_mode, COUNT(*) Total_count
FROM sales
GROUP BY payment_mode
ORDER BY COUNT(*);


--Business Problem Solved: Know which payment options customers prefer.
--Business Impact: Streamline payment processing, prioritize popular modes.


-- ===============================================================================================================================


--🧓 8. How does age group affect purchasing behavior?

SELECT
	CASE
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-55'
		WHEN customer_age BETWEEN 35 AND 50 THEN '35-50'
		ELSE '51+'
	END AS customer_age,
	FORMAT(SUM(price * quantity) , 'C0' , 'en-IN') AS total_purchase
FROM sales
GROUP BY 
	CASE
		WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
		WHEN customer_age BETWEEN 26 AND 35 THEN '26-55'
		WHEN customer_age BETWEEN 35 AND 50 THEN '35-50'
		ELSE '51+'
	END
ORDER BY SUM(price * quantity) DESC;


--Business Problem Solved: Understand customer demographics.
--Business Impact: Targeted marketing and product recommendations by age group.


-- ===============================================================================================================================


--🔁 9. What’s the monthly sales trend?

SELECT * FROM sales;

SELECT
	FORMAT(purchase_date,'yyyy-MM') AS Month_year,
	FORMAT(SUM(price * quantity) , 'C0', 'en-IN') AS Total_sales,
	SUM(quantity) AS total_quantity
FROM sales
GROUP BY FORMAT(purchase_date,'yyyy-MM');

-- =========================================================================

SELECT
	MONTH(purchase_date) as Months,
	FORMAT(SUM(price * quantity) , 'C0', 'en-IN') AS Total_sales,
	SUM(quantity) AS total_quantity
FROM sales
GROUP BY MONTH(purchase_date)
ORDER BY Months;


--Business Problem: Sales fluctuations go unnoticed.
--Business Impact: Plan inventory and marketing according to seasonal trends.


-- ===============================================================================================================================


--🔎 10. Are certain genders buying more specific product categories?

SELECT gender, product_category, COUNT(product_category) AS total_purchase
FROM sales
GROUP BY gender, product_category
ORDER BY gender;


--Business Problem Solved: Gender-based product preferences.
--Business Impact: Personalized ads, gender-focused campaigns.