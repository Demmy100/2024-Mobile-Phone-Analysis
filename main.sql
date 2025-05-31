--•	Which mobile brands and models are the top sellers overall and in specific countries or cities?
SELECT
Brand,
Mobile_Model,
Country,
SUM(Units_Sold) AS total_sold
FROM dbo.onyx_may
GROUP BY Brand,Mobile_Model,Country
ORDER BY Brand, Country, total_sold DESC;

--•	How do sales numbers vary by storage size, color, or operating system (Android vs. iOS)?
SELECT
Operating_System,
Color,
Storage_Size,
SUM(Units_Sold) AS total_sold
FROM dbo.onyx_may
GROUP BY
Operating_System,
Color,
Storage_Size
ORDER BY Operating_System, total_sold DESC;

--•	What is the typical customer profile — age group, gender — for different brands or models?
WITH customer_profile AS 
(
SELECT
Customer_Age_Group,
Brand,
Mobile_Model,
Customer_Gender,
COUNT(*) AS total_Count
FROM dbo.onyx_may
GROUP BY
Customer_Age_Group,
Customer_Gender,
Brand,
Mobile_Model
)

SELECT
Customer_Age_Group,
Customer_Gender,
Brand,
Mobile_Model
FROM
(
SELECT
Customer_Age_Group,
Customer_Gender,
Brand,
Mobile_Model,
total_Count,
ROW_NUMBER() OVER(PARTITION BY Customer_Age_Group, Customer_Gender,Brand ORDER BY total_count DESC) AS rank_order
FROM customer_profile
--ORDER BY Customer_Age_Group, Customer_Gender, Brand, total_Count DESC;
)t
WHERE rank_order = 1
ORDER BY Customer_Age_Group, Customer_Gender, Brand, total_Count DESC;
--ORDER BY Customer_Age_Group, Brand, total_Count DESC;

--•	How do sales and revenues break down across different sales channels (online, partner, in-store) and payment types?
--sales channel
SELECT
Sales_Channel,
SUM(Units_Sold) AS total_sales_channel,
SUM(Total_Revenue) AS total_revenue
FROM dbo.onyx_may
GROUP BY Sales_Channel
ORDER BY total_revenue DESC;

--payment types
SELECT
Payment_Type,
SUM(Units_Sold) AS total_sales_channel,
SUM(Total_Revenue) AS total_revenue
FROM dbo.onyx_may
GROUP BY Payment_Type
ORDER BY total_revenue DESC;

-- •Are there noticeable differences in pricing and sales volume between regions or cities?
--country
SELECT
Country,
ROUND(AVG(Price),0) AS avg_price_country,
ROUND(AVG(Units_Sold),0) AS avg_unit_sold
FROM dbo.onyx_may
GROUP BY Country
ORDER BY avg_unit_sold DESC;

--cities
SELECT
City,
ROUND(AVG(Price),0) AS avg_price_city,
ROUND(AVG(Units_Sold),0) AS avg_unit_sold
FROM dbo.onyx_may
GROUP BY City
ORDER BY avg_unit_sold DESC;

--•Which countries or cities generate the highest total revenue and units sold?
--country
SELECT
Country,
SUM(Total_Revenue) AS total_revenue
FROM dbo.onyx_may
GROUP BY Country
ORDER BY total_revenue DESC;

--city
SELECT
City,
SUM(Total_Revenue) AS total_revenue
FROM dbo.onyx_may
GROUP BY City
ORDER BY total_revenue DESC;

--•Are there patterns in customer demographics based on mobile brand, model, or price range?
WITH customer_demo AS
(
SELECT
Brand,
Mobile_Model,
Price,
CASE
	WHEN Price BETWEEN 300 AND 600 THEN 'Low'
	WHEN Price BETWEEN 601 AND 900 THEN 'Middle'
	WHEN Price BETWEEN 901 AND 1200 THEN 'Very High'
	ELSE 'Most Expensive'
END AS price_range
FROM dbo.onyx_may
)

SELECT
price_range,
Brand,
COUNT(*) AS total_count,
ROW_NUMBER() OVER(PARTITION BY price_range ORDER BY COUNT(*) DESC) AS rank_order
FROM customer_demo
GROUP BY price_range, Brand;

WITH customer_demo AS
(
SELECT
Brand,
Mobile_Model,
Price,
CASE
	WHEN Price BETWEEN 300 AND 600 THEN 'Low'
	WHEN Price BETWEEN 601 AND 900 THEN 'Middle'
	WHEN Price BETWEEN 901 AND 1200 THEN 'Very High'
	ELSE 'Most Expensive'
END AS price_range
FROM dbo.onyx_may
)

SELECT
price_range,
Mobile_Model,
COUNT(*) AS total_count,
ROW_NUMBER() OVER(PARTITION BY price_range ORDER BY COUNT(*) DESC) AS rank_order
FROM customer_demo
GROUP BY price_range, Mobile_Model;

--•How does sales performance change month over month in 2024?
WITH monthly_sales AS
(
SELECT
FORMAT(Transaction_Date, 'yyyy-MM') AS year_month,
SUM(Total_Revenue) AS total_revenue_per_month
FROM dbo.onyx_may
GROUP BY FORMAT(Transaction_Date, 'yyyy-MM')
),
MOM_analysis AS 
(
SELECT
year_month,
total_revenue_per_month,
LAG(total_revenue_per_month) OVER(ORDER BY year_month) AS previous_month_sales,
ROUND(
(CAST(total_revenue_per_month AS FLOAT) - LAG(total_revenue_per_month) OVER(ORDER BY year_month)) / NULLIF(CAST(LAG(total_revenue_per_month) OVER (ORDER BY year_month) AS FLOAT), 0) * 100, 2) AS mom_change_percent
FROM monthly_sales
)

SELECT
    year_month,
    total_revenue_per_month,
    previous_month_sales,
    CASE 
        WHEN mom_change_percent IS NULL THEN NULL
        ELSE CONCAT(CAST(mom_change_percent AS VARCHAR), '%')
    END AS mom_change_percent
FROM MOM_analysis
ORDER BY year_month;

--•	Are there correlations between customer age groups and the type of devices they purchase (for example, younger customers preferring certain brands)?
SELECT
*
FROM
(
SELECT
Customer_Age_Group,
Brand,
COUNT(*) AS total_count,
ROW_NUMBER() OVER(PARTITION BY Customer_Age_Group ORDER BY COUNT(*) DESC) AS ranking_order
FROM dbo.onyx_may
GROUP BY Customer_Age_Group, Brand
)t
WHERE ranking_order = 1;
--ORDER BY Customer_Age_Group, total_count DESC