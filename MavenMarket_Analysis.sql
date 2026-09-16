USE Final_Project;
GO

-- ============================================
-- SECTION A: Overall Business Performance
-- ============================================

-- --------------------------------------------
-- Q1: What is the company's total revenue, profit, and profit margin?
-- --------------------------------------------
SELECT 
    SUM(t.quantity * p.product_retail_price) AS Total_Revenue,
    SUM(t.quantity * p.product_cost) AS Total_Cost,
    SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost) AS Gross_Profit,
    ROUND( (SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost)) 
        / SUM(t.quantity * p.product_retail_price) * 100, 2) AS Profit_Margin_Percent
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id;

-- --------------------------------------------
-- Q2: How are revenue and profit changing over time?
-- --------------------------------------------
SELECT 
    c.Year,
    c.Month,
    SUM(t.quantity * p.product_retail_price) AS Revenue,
    SUM(t.quantity * p.product_cost) AS Cost,
    SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost) AS Profit
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Calendar c ON t.transaction_date = c.date
GROUP BY c.Year, c.Month
ORDER BY c.Year, 
    CASE c.Month
        WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
        WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
        WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
        WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
    END;

-- --------------------------------------------
-- Q3: Which periods generate the highest and lowest sales?
-- --------------------------------------------

-- Top 5 Sales Months
SELECT TOP 5
    c.Year,
    c.Month,
    SUM(t.quantity * p.product_retail_price) AS Revenue
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Calendar c ON t.transaction_date = c.date
GROUP BY c.Year, c.Month
ORDER BY Revenue DESC;

SELECT TOP 5
    c.Year,
    c.Month,
    SUM(t.quantity * p.product_retail_price) AS Revenue
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Calendar c ON t.transaction_date = c.date
GROUP BY c.Year, c.Month
ORDER BY Revenue ASC;

-- --------------------------------------------
-- Q4: Is the business achieving sustainable revenue growth?
-- -------------------------------------------- 
WITH Yearly_Revenue AS (
    SELECT 
        c.Year,
        SUM(t.quantity * p.product_retail_price) AS Revenue
    FROM MavenMarket_Transactions_All t
    JOIN MavenMarket_Products p ON t.product_id = p.product_id
    JOIN MavenMarket_Calendar c ON t.transaction_date = c.date
    GROUP BY c.Year
)
SELECT 
    Year,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year) AS Previous_Year_Revenue,
    ROUND((Revenue - LAG(Revenue) OVER (ORDER BY Year)) 
        / LAG(Revenue) OVER (ORDER BY Year) * 100, 2) AS Revenue_Growth_Percent
FROM Yearly_Revenue
ORDER BY Year;

-- -------------------------------------------- 
-- Q5: What is the average transaction value?
-- --------------------------------------------
SELECT 
    AVG(t.quantity * p.product_retail_price) AS Average_Transaction_Value
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id;


-- ============================================
-- SECTION B: Product Performance
-- ============================================

-- ------------------------------------------------
-- Q1: Which products generate the highest revenue?  
-- ------------------------------------------------
SELECT TOP 10
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(t.quantity * p.product_retail_price) AS Total_Revenue
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_brand
ORDER BY Total_Revenue DESC;

-- ------------------------------------------------
-- Q2: Which products generate the highest profit?
-- ------------------------------------------------
SELECT TOP 10
    p.product_id,
    p.product_name,
    p.product_brand,
    SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost) AS Total_Profit
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_brand
ORDER BY Total_Profit DESC;

-- --------------------------------------------
-- Q3: Which products have high sales but low profit margins?
-- --------------------------------------------
WITH Product_Stats AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(t.quantity * p.product_retail_price) AS Total_Revenue,
        (SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost))
        / SUM(t.quantity * p.product_retail_price) * 100 AS Profit_Margin_Percent
    FROM MavenMarket_Transactions_All t
    JOIN MavenMarket_Products p ON t.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
)
SELECT 
    product_id,
    product_name,
    Total_Revenue,
    ROUND(Profit_Margin_Percent, 2) AS Profit_Margin_Percent
FROM Product_Stats
WHERE 
    Total_Revenue > (SELECT AVG(Total_Revenue) FROM Product_Stats) 
    AND 
    Profit_Margin_Percent < (SELECT AVG(Profit_Margin_Percent) FROM Product_Stats) 
ORDER BY Total_Revenue DESC;

-- --------------------------------------------
-- Q4: Which product brands contribute the most to overall revenue?
-- --------------------------------------------
SELECT 
    p.product_brand,
    SUM(t.quantity * p.product_retail_price) AS Total_Revenue
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
GROUP BY p.product_brand
ORDER BY Total_Revenue DESC;

-- --------------------------------------------
-- Q5: Which products have the highest return rates?
-- --------------------------------------------
WITH Sales_Per_Product AS (
    SELECT 
        product_id,
        SUM(quantity) AS Units_Sold
    FROM MavenMarket_Transactions_All
    GROUP BY product_id
),
Returns_Per_Product AS (
    SELECT 
        product_id,
        SUM(quantity) AS Units_Returned
    FROM [MavenMarket_Returns_1997-1998]
    GROUP BY product_id
)
SELECT TOP 10
    p.product_id,
    p.product_name,
    s.Units_Sold,
    r.Units_Returned,
    ROUND(CAST(r.Units_Returned AS FLOAT) / s.Units_Sold * 100, 2) AS Return_Rate_Percent 
FROM Sales_Per_Product s
JOIN Returns_Per_Product r ON s.product_id = r.product_id 
JOIN MavenMarket_Products p ON s.product_id = p.product_id 
ORDER BY Return_Rate_Percent DESC;

-- --------------------------------------------
-- Q6: Which products are underperforming (lowest-selling)?
-- --------------------------------------------
SELECT TOP 10
    p.product_id,
    p.product_name,
    p.product_brand,
    ISNULL(SUM(t.quantity), 0) AS Units_Sold,
    ISNULL(SUM(t.quantity * p.product_retail_price), 0) AS Total_Revenue
FROM MavenMarket_Products p
LEFT JOIN MavenMarket_Transactions_All t ON t.product_id = p.product_id 
GROUP BY p.product_id, p.product_name, p.product_brand
ORDER BY Units_Sold ASC;

-- ============================================
-- SECTION C: Store & Regional Performance 
-- ============================================
-- --------------------------------------------
-- Q1: Which stores generate the highest revenue?
-- --------------------------------------------
SELECT TOP 10
    s.store_id,
    s.store_name,
    SUM(t.quantity * p.product_retail_price) AS Total_Revenue
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Stores s ON t.store_id = s.store_id
GROUP BY s.store_id, s.store_name
ORDER BY Total_Revenue DESC;

-- --------------------------------------------
-- Q2: Which stores generate the highest profit?
-- --------------------------------------------
SELECT TOP 10
    s.store_id,
    s.store_name,
    SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost) AS Total_Profit
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Stores s ON t.store_id = s.store_id
GROUP BY s.store_id, s.store_name
ORDER BY Total_Profit DESC;

-- --------------------------------------------
-- Q3: Which regions are outperforming or underperforming?
-- --------------------------------------------

WITH RegionSales AS (
    SELECT 
        s.region_id,
        SUM(t.quantity) AS total_sold
    FROM MavenMarket_Transactions_All t
    JOIN MavenMarket_Stores s ON t.store_id = s.store_id
    GROUP BY s.region_id
),
RegionReturns AS (
    SELECT 
        s.region_id,
        SUM(r.quantity) AS total_returned
    FROM [dbo].[MavenMarket_Returns_1997-1998] r
    JOIN MavenMarket_Stores s ON r.store_id = s.store_id
    GROUP BY s.region_id
)
SELECT 
    reg.region_id,
    reg.sales_region,
    reg.sales_district,
    COALESCE(rs.total_sold, 0) AS total_units_sold,
    COALESCE(rr.total_returned, 0) AS total_units_returned,
    ROUND(
        (CAST(COALESCE(rr.total_returned, 0) AS FLOAT) / NULLIF(rs.total_sold, 0)) * 100, 
        2
    ) AS return_rate_pct
FROM MavenMarket_Regions reg
LEFT JOIN RegionSales rs ON reg.region_id = rs.region_id
LEFT JOIN RegionReturns rr ON reg.region_id = rr.region_id
ORDER BY return_rate_pct DESC; 

-- --------------------------------------------
-- Q4: How does store performance vary across regions?
-- -------------------------------------------- 
WITH Store_Revenue AS (
    SELECT 
        s.store_id,
        s.store_name,
        r.sales_region,
        SUM(t.quantity * p.product_retail_price) AS Store_Revenue
    FROM MavenMarket_Transactions_All t
    JOIN MavenMarket_Products p ON t.product_id = p.product_id
    JOIN MavenMarket_Stores s ON t.store_id = s.store_id
    JOIN MavenMarket_Regions r ON s.region_id = r.region_id
    GROUP BY s.store_id, s.store_name, r.sales_region
)
SELECT 
    store_id,
    store_name,
    sales_region,
    Store_Revenue,
    ROUND(AVG(Store_Revenue) OVER (PARTITION BY sales_region), 2) AS Region_Avg_Revenue,
    ROUND(Store_Revenue - AVG(Store_Revenue) OVER (PARTITION BY sales_region), 2) AS Diff_From_Region_Avg
FROM Store_Revenue
ORDER BY sales_region, Store_Revenue DESC;

-- --------------------------------------------
-- Q5: Which stores have strong sales but weak profitability?
-- --------------------------------------------
WITH Store_Stats AS (
    SELECT 
        s.store_id,
        s.store_name,
        SUM(t.quantity * p.product_retail_price) AS Total_Revenue,
        (SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost))
        / SUM(t.quantity * p.product_retail_price) * 100 AS Profit_Margin_Percent
    FROM MavenMarket_Transactions_All t
    JOIN MavenMarket_Products p ON t.product_id = p.product_id
    JOIN MavenMarket_Stores s ON t.store_id = s.store_id
    GROUP BY s.store_id, s.store_name
)
SELECT 
    store_id,
    store_name,
    Total_Revenue,
    ROUND(Profit_Margin_Percent, 2) AS Profit_Margin_Percent
FROM Store_Stats
WHERE 
    Total_Revenue > (SELECT AVG(Total_Revenue) FROM Store_Stats)
    AND 
    Profit_Margin_Percent < (SELECT AVG(Profit_Margin_Percent) FROM Store_Stats)
ORDER BY Total_Revenue DESC;

-- --------------------------------------------
-- Q6: Are there geographical areas with consistently low performance?
-- --------------------------------------------
WITH Region_Revenue AS (
    SELECT 
        r.sales_region,
        SUM(t.quantity * p.product_retail_price) AS Total_Revenue
    FROM MavenMarket_Transactions_All t
    JOIN MavenMarket_Products p ON t.product_id = p.product_id
    JOIN MavenMarket_Stores s ON t.store_id = s.store_id
    JOIN MavenMarket_Regions r ON s.region_id = r.region_id
    GROUP BY r.sales_region
)
SELECT 
    sales_region,
    Total_Revenue
FROM Region_Revenue
WHERE Total_Revenue < (SELECT AVG(Total_Revenue) FROM Region_Revenue)
ORDER BY Total_Revenue ASC;






-- ============================================
-- SECTION D: Customer Analysis
-- ============================================

-- --------------------------------------------
-- Q1: Who are Maven Market's most valuable customers?
-- --------------------------------------------
SELECT TOP 10
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(t.quantity * p.product_retail_price) AS Total_Spend,
	SUM(t.quantity * (p.product_retail_price - p.product_cost)) AS Total_Profit
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Customers c ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY Total_Spend DESC;

-- --------------------------------------------
-- Q2: Which customer demographics generate the highest revenue?
-- --------------------------------------------
SELECT 
    c.gender,
    c.marital_status,
    SUM(t.quantity * p.product_retail_price) AS Total_Revenue,
    COUNT(DISTINCT c.customer_id) AS Number_Of_Customers
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Customers c ON t.customer_id = c.customer_id
GROUP BY c.gender, c.marital_status
ORDER BY Total_Revenue DESC;

-- --------------------------------------------
-- Q3: What is the average customer spend (monetary)?
-- --------------------------------------------
WITH Customer_Spend AS (
    SELECT 
        c.customer_id,
        SUM(t.quantity * p.product_retail_price) AS Total_Spend
    FROM MavenMarket_Transactions_All t
    JOIN MavenMarket_Products p ON t.product_id = p.product_id
    JOIN MavenMarket_Customers c ON t.customer_id = c.customer_id
    GROUP BY c.customer_id
)
SELECT 
    ROUND(AVG(Total_Spend), 2) AS Average_Customer_Spend
FROM Customer_Spend;

-- --------------------------------------------
-- Q4: How frequently do customers make purchases?
-- --------------------------------------------
WITH Customer_Purchase_Count AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT transaction_date) AS Purchase_Occasions 
    FROM MavenMarket_Transactions_All
    GROUP BY customer_id
)
SELECT 
    ROUND(AVG(Purchase_Occasions * 1.0) / 2, 2) AS Avg_Purchase_Frequency_Per_Year
FROM Customer_Purchase_Count;

-- --------------------------------------------
-- Q5: What percentage of customers are repeat customers?
-- --------------------------------------------
WITH Customer_Purchase_Count AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT transaction_date) AS Purchase_Occasions
    FROM MavenMarket_Transactions_All
    GROUP BY customer_id
)
SELECT 
    (SELECT COUNT(*) FROM Customer_Purchase_Count WHERE Purchase_Occasions > 1) AS Repeat_Customers,
    (SELECT COUNT(*) FROM Customer_Purchase_Count) AS Total_Customers,
    ROUND(
        CAST((SELECT COUNT(*) FROM Customer_Purchase_Count WHERE Purchase_Occasions > 1) AS FLOAT)
        / (SELECT COUNT(*) FROM Customer_Purchase_Count) * 100, 2
    ) AS Repeat_Customer_Percent;

-- --------------------------------------------
-- Q6: Which customer segments contribute the most to revenue and profit?
-- --------------------------------------------
SELECT 
    c.yearly_income AS Income_Segment,
    SUM(t.quantity * p.product_retail_price) AS Total_Revenue,
    SUM(t.quantity * p.product_retail_price) - SUM(t.quantity * p.product_cost) AS Total_Profit,
    COUNT(DISTINCT c.customer_id) AS Number_Of_Customers
FROM MavenMarket_Transactions_All t
JOIN MavenMarket_Products p ON t.product_id = p.product_id
JOIN MavenMarket_Customers c ON t.customer_id = c.customer_id
GROUP BY c.yearly_income
ORDER BY Total_Revenue DESC;

-- ============================================
-- SECTION E: Returns Analysis
-- ============================================

---------------------------------------------
-- 1. What percentage of purchased products are returned?
---------------------------------------------
SELECT 
    (SELECT SUM(quantity) FROM [MavenMarket_Returns_1997-1998]) AS total_returned_units,
    (SELECT SUM(quantity) FROM MavenMarket_Transactions_All) AS total_purchased_units,
    ROUND(
        (CAST((SELECT SUM(quantity) FROM [MavenMarket_Returns_1997-1998]) AS FLOAT) / 
        (SELECT SUM(quantity) FROM MavenMarket_Transactions_All)) * 100, 2
    ) AS overall_return_rate_percentage;


-------------------------------------------
-- 2. Which products have the highest return rates?
-------------------------------------------
WITH ProductSales AS (
    SELECT product_id, SUM(quantity) AS total_sold
    FROM MavenMarket_Transactions_All
    GROUP BY product_id
),
ProductReturns AS (
    SELECT product_id, SUM(quantity) AS total_returned
    FROM [dbo].[MavenMarket_Returns_1997-1998]
    GROUP BY product_id
)
SELECT TOP 10
    p.product_id,
    p.product_name,
    p.product_brand,
    COALESCE(s.total_sold, 0) AS units_sold,
    COALESCE(r.total_returned, 0) AS units_returned,
    ROUND((CAST(COALESCE(r.total_returned, 0) AS FLOAT) / NULLIF(s.total_sold, 0)) * 100, 2) AS return_rate_pct
FROM MavenMarket_Products p
LEFT JOIN ProductSales s ON p.product_id = s.product_id
LEFT JOIN ProductReturns r ON p.product_id = r.product_id
WHERE COALESCE(s.total_sold, 0) > 0
ORDER BY return_rate_pct DESC;

---------------------------------
-- 3. Which stores have the highest return rates?
---------------------------------
WITH StoreSales AS (
    SELECT store_id, SUM(quantity) AS total_sold
    FROM MavenMarket_Transactions_All
    GROUP BY store_id
),
StoreReturns AS (
    SELECT store_id, SUM(quantity) AS total_returned
    FROM [dbo].[MavenMarket_Returns_1997-1998]
    GROUP BY store_id
)
SELECT 
    st.store_id,
    st.store_name,
    st.store_city,
    st.store_country,
    COALESCE(ss.total_sold, 0) AS total_units_sold,
    COALESCE(sr.total_returned, 0) AS total_units_returned,
    ROUND((CAST(COALESCE(sr.total_returned, 0) AS FLOAT) / NULLIF(ss.total_sold, 0)) * 100, 2) AS return_rate_pct
FROM MavenMarket_Stores st
LEFT JOIN StoreSales ss ON st.store_id = ss.store_id
LEFT JOIN StoreReturns sr ON st.store_id = sr.store_id
ORDER BY return_rate_pct DESC;


-----------------------------------
-- 4. Are return rates increasing over time?
-----------------------------------
WITH MonthlySales AS (
    SELECT 
        DATETRUNC(month, transaction_date) AS month_start,
        SUM(quantity) AS total_sold
    FROM MavenMarket_Transactions_All
    GROUP BY DATETRUNC(month, transaction_date)
),
MonthlyReturns AS (
    SELECT 
        DATETRUNC(month, return_date) AS month_start,
        SUM(quantity) AS total_returned
    FROM [dbo].[MavenMarket_Returns_1997-1998]
    GROUP BY DATETRUNC(month, return_date)
)
SELECT 
    ms.month_start,
    ms.total_sold,
    COALESCE(mr.total_returned, 0) AS total_returned,
    ROUND((CAST(COALESCE(mr.total_returned, 0) AS FLOAT) / ms.total_sold) * 100, 2) AS monthly_return_rate_pct
FROM MonthlySales ms
LEFT JOIN MonthlyReturns mr ON ms.month_start = mr.month_start
ORDER BY ms.month_start ASC;

--------------------------------------------------------
-- 5. Which brands or product categories contribute most to returned units?
--------------------------------------------------------
SELECT TOP 10
    p.product_brand,
    SUM(r.quantity) AS total_returned_units,
    ROUND(
        (CAST(SUM(r.quantity) AS FLOAT) / (SELECT SUM(quantity) FROM [dbo].[MavenMarket_Returns_1997-1998])) * 100, 
        2
    ) AS contribution_to_total_returns_pct
FROM [dbo].[MavenMarket_Returns_1997-1998] r
JOIN MavenMarket_Products p ON r.product_id = p.product_id
GROUP BY p.product_brand
ORDER BY total_returned_units DESC;

--------------------------------------
-- 6. How much revenue is potentially affected by returns?
--------------------------------------
SELECT 
    SUM(r.quantity) AS total_returned_units,
    ROUND(SUM(r.quantity * p.product_retail_price), 2) AS total_lost_revenue_dollars,
    ROUND(AVG(r.quantity * p.product_retail_price), 2) AS avg_return_value_per_transaction
FROM [dbo].[MavenMarket_Returns_1997-1998] r
JOIN MavenMarket_Products p ON r.product_id = p.product_id;
