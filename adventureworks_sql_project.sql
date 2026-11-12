/* =============================================================================
   AdventureWorks SQL Project
   =============================================================================
   Author   : Naresh
   Dialect  : SQLite
   Dataset  : AdventureWorks, supplied with a data dictionary documenting the
              full schema (71 tables). Only the tables below are used.

   Tables used
     product, productReview, productModelProductDescriptionCulture,
     productDescription, productCategory, productSubcategory,
     salesOrderDetail, salesOrderHeader, salesPerson, currencyRate

   Business questions
     1. Which products are rated highest, and is there enough review data to
        use ratings as a measure of popularity?
     2. Which products and subcategories actually sell the most (units)?
     3. Who are the top salespeople, and does commission rate relate to sales?
     4. Does the answer change when we respect the currency each order was
        paid in?
        
	Notes
     - The 2014 filters cover only the months present in the data.
     - Per the project brief, order amounts are in each order's local currency
       and are not converted to USD, so the totals in Exercises 5 to 7 mix
       currencies. Exercise 9 groups by currency to compare like for like.
	========================================================================== */


/* =============================================================================
   EXERCISE 1: Rank products by average review rating
   ========================================================================== */

-- Why: to see which products customers rate highest, and how many reviews sit
-- behind each average. INNER JOIN keeps only products that have been reviewed.
-- Ordering by average rating and then review count gives a sensible ranking when
-- two products have the same average.
SELECT
    p.ProductID,
    p.Name,
    AVG(pr.Rating) AS avgrating,
    COUNT(pr.ProductReviewID) AS num_ratings
FROM product AS p
INNER JOIN productReview AS pr
    ON p.ProductID = pr.ProductID
GROUP BY
    p.ProductID,
    p.Name
ORDER BY
    avgrating DESC,
    num_ratings DESC;

-- Finding: only a handful of products have reviews, which is too thin to
-- correlate ratings with sales. The analysis therefore moves to sales data.


/* =============================================================================
   EXERCISE 2: Best-selling products with English descriptions
   ========================================================================== */

-- 2.1 Why: product descriptions are stored once per culture. Filtering to the
-- English culture ('en') gives one readable description per product model.
SELECT
    pmpdc.ProductModelID,
    pd.Description
FROM productModelProductDescriptionCulture AS pmpdc
INNER JOIN productDescription AS pd
    ON pmpdc.ProductDescriptionID = pd.ProductDescriptionID
WHERE pmpdc.CultureID = 'en';


-- 2.2 Why: to find the top 10 products by units sold. The 2.1 query is wrapped
-- in a CTE so it can be joined to product (for the name) and salesOrderDetail
-- (for sales). SUM(OrderQty) is used instead of COUNT(*) because one order line
-- can cover several units.
WITH english_description AS (
    SELECT
        pmpdc.ProductModelID,
        pd.Description
    FROM productModelProductDescriptionCulture AS pmpdc
    INNER JOIN productDescription AS pd
        ON pmpdc.ProductDescriptionID = pd.ProductDescriptionID
    WHERE pmpdc.CultureID = 'en'
)
SELECT
    ed.ProductModelID,
    ed.Description,
    p.Name,
    SUM(sod.OrderQty) AS total_orders
FROM english_description AS ed
INNER JOIN product AS p
    ON ed.ProductModelID = p.ProductModelID
INNER JOIN salesOrderDetail AS sod
    ON p.ProductID = sod.ProductID
GROUP BY
    ed.ProductModelID,
    ed.Description,
    p.Name
ORDER BY
    total_orders DESC
LIMIT 10;



/* =============================================================================
   EXERCISE 3: Units sold and list price by product subcategory
   ========================================================================== */

-- 3.1 Why: first building block. Total units sold for every product, so that
-- sales volume can later be attached to category data.
SELECT
    ProductID,
    SUM(OrderQty) AS quantity
FROM salesOrderDetail
GROUP BY
    ProductID;

-- 3.2 Why: second building block. List price for each product together with its
-- category and subcategory. product has no direct link to productCategory, so
-- the join goes through productSubcategory.
SELECT
    p.ProductID,
    pc.Name AS category,
    psc.Name AS subcategory,
    p.ListPrice
FROM product AS p
INNER JOIN productSubcategory AS psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN productCategory AS pc
    ON psc.ProductCategoryID = pc.ProductCategoryID;

-- 3.3 Why: to compare average list price with total units sold per subcategory.
-- Both previous queries become CTEs (one WITH, separated by a comma) and are
-- joined on ProductID. Only products that have been sold are included.

WITH quantity_sold AS (
    SELECT
        ProductID,
        SUM(OrderQty) AS quantity
    FROM salesOrderDetail
    GROUP BY
        ProductID
),
product_details AS (
    SELECT
        p.ProductID,
        p.ListPrice,
        pc.Name AS category,
        psc.Name AS subcategory
    FROM product AS p
    INNER JOIN productSubcategory AS psc
        ON p.ProductSubcategoryID = psc.ProductSubcategoryID
    INNER JOIN productCategory AS pc
        ON psc.ProductCategoryID = pc.ProductCategoryID
)
SELECT
    pd.category,
    pd.subcategory,
    AVG(pd.ListPrice) AS average_price_in_subcategory,
    SUM(qs.quantity) AS total_items_sold_in_subcategory
FROM product_details AS pd
INNER JOIN quantity_sold AS qs
    ON pd.ProductID = qs.ProductID
GROUP BY
    pd.category,
    pd.subcategory;


/* =============================================================================
   EXERCISE 4: Top five salespeople by the stored year-to-date figure
   ========================================================================== */

-- Why: a first view of top performers using the SalesYTD column in salesPerson.
-- This figure is stored rather than calculated from orders, so Exercises 5 and 6
-- test whether it can be trusted.
SELECT
    BusinessEntityID,
    SalesYTD
FROM salesPerson
ORDER BY
    SalesYTD DESC
LIMIT 5;


/* =============================================================================
   EXERCISE 5: Top five salespeople from actual 2014 orders
   ========================================================================== */

-- Why: to rebuild the ranking from order records (SubTotal in salesOrderHeader)
-- instead of the stored SalesYTD value. Orders without a salesperson (typically
-- online orders) are excluded. The date filter uses >= start and < next start so
-- it stays correct if OrderDate carries a time component.
SELECT
    SalesPersonID,
    SUM(SubTotal) AS total_sales
FROM salesOrderHeader
WHERE
    SalesPersonID IS NOT NULL
    AND SalesPersonID <> ''
    AND OrderDate >= '2014-01-01'
    AND OrderDate < '2015-01-01'
GROUP BY
    SalesPersonID
ORDER BY
    total_sales DESC
LIMIT 5;


/* =============================================================================
   EXERCISE 6: Validate SubTotal by recalculating it from order lines
   ========================================================================== */

-- 6.1 Why: SubTotal is a derived value, so it should be checked rather than
-- trusted. This recalculates each order's total from its lines:
-- quantity x unit price x (1 - discount). LIMIT 10 is used while exploring a
-- large table; it is removed when the query is reused in 6.2.
SELECT
    SalesOrderID,
    SUM(OrderQty * UnitPrice * (1 - UnitPriceDiscount)) AS ordertotal
FROM salesOrderDetail
GROUP BY
    SalesOrderID
LIMIT 10;

-- 6.2 Why: to rank 2014 salespeople using the recalculated totals. One CTE holds
-- the per-order totals (6.1 without LIMIT), another holds the 2014 orders that
-- have a salesperson, and the final step joins and sums them per salesperson.
WITH order_totals AS (
    SELECT
        SalesOrderID,
        SUM(OrderQty * UnitPrice * (1 - UnitPriceDiscount)) AS ordertotal
    FROM salesOrderDetail
    GROUP BY
        SalesOrderID
),
orders_2014 AS (
    SELECT
        SalesOrderID,
        SalesPersonID
    FROM salesOrderHeader
    WHERE
        SalesPersonID IS NOT NULL
        AND SalesPersonID <> ''
        AND OrderDate >= '2014-01-01'
        AND OrderDate < '2015-01-01'
)
SELECT
    o.SalesPersonID,
    SUM(ot.ordertotal) AS ordertotalsum
FROM orders_2014 AS o
INNER JOIN order_totals AS ot
    ON o.SalesOrderID = ot.SalesOrderID
GROUP BY
    o.SalesPersonID
ORDER BY
    ordertotalsum DESC
LIMIT 5;


/* =============================================================================
   EXERCISE 7: Do higher-selling salespeople have higher commission rates?
   ========================================================================== */

-- Why: to test for a relationship between 2014 sales and commission rate. The
-- 6.2 logic is reused without LIMIT (every salesperson is needed for a
-- correlation) and joined to salesPerson on BusinessEntityID = SalesPersonID.
WITH order_totals AS (
    SELECT
        SalesOrderID,
        SUM(OrderQty * UnitPrice * (1 - UnitPriceDiscount)) AS ordertotal
    FROM salesOrderDetail
    GROUP BY
        SalesOrderID
),
orders_2014 AS (
    SELECT
        SalesOrderID,
        SalesPersonID
    FROM salesOrderHeader
    WHERE
        SalesPersonID IS NOT NULL
        AND SalesPersonID <> ''
        AND OrderDate >= '2014-01-01'
        AND OrderDate < '2015-01-01'
),
salesperson_sales AS (
    SELECT
        o.SalesPersonID AS salespersonid,
        SUM(ot.ordertotal) AS ordertotalsum
    FROM orders_2014 AS o
    INNER JOIN order_totals AS ot
        ON o.SalesOrderID = ot.SalesOrderID
    GROUP BY
        o.SalesPersonID
)
SELECT
    ss.salespersonid,
    ss.ordertotalsum,
    sp.CommissionPct AS commissionpct
FROM salesperson_sales AS ss
INNER JOIN salesPerson AS sp
    ON ss.salespersonid = sp.BusinessEntityID
ORDER BY
    ss.salespersonid;


/* =============================================================================
   EXERCISE 8: Which currency was each order paid in?
   ========================================================================== */

-- 8.1 Why: sales are recorded in local currency, so each order needs its
-- currency. FromCurrencyCode is always USD, so ToCurrencyCode is the currency
-- paid. USD orders have no CurrencyRateID, so a LEFT JOIN is essential: an
-- INNER JOIN would silently drop every USD order.
SELECT
    soh.SalesPersonID AS salespersonid,
    soh.SalesOrderID AS salesorderid,
    soh.CurrencyRateID AS currencyrateid,
    cr.ToCurrencyCode AS tocurrencycode
FROM salesOrderHeader AS soh
LEFT JOIN currencyRate AS cr
    ON soh.CurrencyRateID = cr.CurrencyRateID
WHERE
    soh.SalesPersonID IS NOT NULL
    AND soh.SalesPersonID <> ''
    AND soh.OrderDate >= '2014-01-01'
    AND soh.OrderDate < '2015-01-01'
ORDER BY
    soh.SalesPersonID
LIMIT 10;

-- 8.2 Why: NULL in the currency column would confuse anyone unfamiliar with the
-- database. A CASE expression replaces NULL with 'USD', which is what a missing
-- rate means here, and the internal CurrencyRateID column is dropped.
SELECT
    soh.SalesPersonID AS salespersonid,
    soh.SalesOrderID AS salesorderid,
    CASE
        WHEN cr.ToCurrencyCode IS NULL THEN 'USD'
        ELSE cr.ToCurrencyCode
    END AS tocurrencycode
FROM salesOrderHeader AS soh
LEFT JOIN currencyRate AS cr
    ON soh.CurrencyRateID = cr.CurrencyRateID
WHERE
    soh.SalesPersonID IS NOT NULL
    AND soh.SalesPersonID <> ''
    AND soh.OrderDate >= '2014-01-01'
    AND soh.OrderDate < '2015-01-01'
ORDER BY
    soh.SalesPersonID,
    soh.SalesOrderID
LIMIT 10;

/* =============================================================================
   EXERCISE 9: Salesperson totals and commission, split by currency
   ========================================================================== */

-- Why: Exercise 7 added up amounts in different currencies. This repeats it with
-- the currency included, grouped per salesperson and currency, and sorted by
-- currency then total sales (highest first), so the best salesperson within each
-- currency is easy to see. 
WITH orderTotals AS (
    SELECT
        SalesOrderID,
        SUM(OrderQty * UnitPrice * (1 - UnitPriceDiscount)) AS ordertotal
    FROM salesOrderDetail
    GROUP BY
        SalesOrderID
),
salesPersonAndOrder AS (
    SELECT
        soh.SalesOrderID,
        soh.SalesPersonID,
        CASE
            WHEN cr.ToCurrencyCode IS NULL THEN 'USD'
            ELSE cr.ToCurrencyCode
        END AS tocurrencycode
    FROM salesOrderHeader AS soh
    LEFT JOIN currencyRate AS cr
        ON soh.CurrencyRateID = cr.CurrencyRateID
    WHERE
        soh.SalesPersonID IS NOT NULL
        AND soh.SalesPersonID <> ''
        AND soh.OrderDate >= '2014-01-01'
        AND soh.OrderDate < '2015-01-01'
),
salesPersonTotalSales AS (
    SELECT
        spo.SalesPersonID AS salespersonid,
        spo.tocurrencycode,
        SUM(ot.ordertotal) AS ordertotalsum
    FROM salesPersonAndOrder AS spo
    INNER JOIN orderTotals AS ot
        ON spo.SalesOrderID = ot.SalesOrderID
    GROUP BY
        spo.SalesPersonID,
        spo.tocurrencycode
)
SELECT
    sts.salespersonid,
    sts.tocurrencycode,
    sts.ordertotalsum,
    sp.CommissionPct AS commissionpct
FROM salesPersonTotalSales AS sts
INNER JOIN salesPerson AS sp
    ON sts.salespersonid = sp.BusinessEntityID
ORDER BY
    sts.tocurrencycode ASC,
    sts.ordertotalsum DESC;
    
/*========================================================================== */
