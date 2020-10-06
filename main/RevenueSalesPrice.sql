IF OBJECT_ID('tempdb..#prices') IS NOT NULL
BEGIN
DROP TABLE #prices
END
CREATE TABLE #prices(
[product] varchar(12),
[price_effective_date] date,
[price] int
)
INSERT INTO #prices
SELECT 'product_1',	  '2018-01-01',	 50
UNION ALL
SELECT 'product_2',   '2018-01-01',  40
UNION ALL
SELECT 'product_1',   '2018-01-03',  25
UNION ALL
SELECT 'product_2',   '2018-01-05',  20
UNION ALL
SELECT 'product_1',   '2018-01-10',  50
UNION ALL
SELECT 'product_2',   '2018-01-12',  40
GO

IF OBJECT_ID('tempdb..#sales') IS NOT NULL
BEGIN
DROP TABLE #sales
END
CREATE TABLE #sales(
[product] varchar(12),
[sales_date] date,
[quantity] int
)
INSERT INTO #sales
SELECT 'product_1',   '2018-01-01',  10
UNION ALL
SELECT 'product_2',   '2018-01-02',  12
UNION ALL
SELECT 'product_1',   '2018-01-04',  50
UNION ALL
SELECT 'product_2',   '2018-01-06',  70
UNION ALL
SELECT 'product_1',   '2018-01-12',  8
UNION ALL
SELECT 'product_2',   '2018-01-15',  9
GO

WITH ProductPrices AS
(
    SELECT Product, price_effective_date, price
        ,rn=ROW_NUMBER() OVER (PARTITION BY Product ORDER BY price_effective_date)
    FROM #prices
)
,IndexedPrices AS(
SELECT a.product, PriceStartDate=a.price_effective_date, PriceEndDate=DATEADD(DAY,-1,b.price_effective_date), a.price
FROM ProductPrices a
LEFT JOIN ProductPrices b ON a.Product = b.Product AND b.rn = a.rn + 1
)
,QtyPrices AS(SELECT s.*,
discounted_price = x.price,
full_price = CASE WHEN s.product = 'product_1' AND x.PriceStartDate BETWEEN '2018-01-03' AND '2018-01-09'
             THEN CAST(x.price*2.0 AS INT) ELSE x.price END
FROM #sales s
LEFT JOIN(
SELECT ix.product, ix.PriceStartDate,
       CASE WHEN ix.PriceEndDate IS NULL THEN CAST(GETDATE() AS DATE) ELSE ix.PriceEndDate END AS PriceEndDate,
	   ix.price
FROM IndexedPrices ix
) x
ON s.product = x.product
AND s.sales_date BETWEEN x.PriceStartDate AND x.PriceEndDate
)
SELECT RevenueType = 'TotalRevenueWithDiscounts', [Value] = SUM(discounted_price*quantity)
FROM QtyPrices
UNION ALL
SELECT RevenueType = 'TotalRevenueWithoutDiscounts', [Value] = SUM(full_price*quantity)
FROM QtyPrices