# AdventureWorks SQL Analysis

SQL analysis of the AdventureWorks sample database to understand which products sell, who sells them, and whether commission rates relate to sales.

## The dataset story

AdventureWorks is Microsoft's sample database for a fictional bicycle manufacturer, Adventure Works Cycles. The company sells bikes, components, clothing and accessories through its own salespeople and online, to customers in several countries. That means orders are placed in different currencies and product descriptions exist in several languages.

This project uses SQL to answer four practical questions about that business:

1. Are product reviews a usable measure of popularity?
2. Which products and product subcategories sell the most?
3. Who are the top salespeople, and does commission rate relate to sales?
4. Does the picture change once the currency of each order is considered?

## Tables used

The database documents 71 tables in its data dictionary. This analysis uses 10 of them:

| Table | What it holds | Key columns used |
|---|---|---|
| `product` | One row per product | `ProductID`, `Name`, `ListPrice`, `ProductSubcategoryID`, `ProductModelID` |
| `productReview` | Customer reviews of products | `ProductID`, `Rating` |
| `productSubcategory` | Subcategories of products | `ProductSubcategoryID`, `ProductCategoryID`, `Name` |
| `productCategory` | Top-level product categories | `ProductCategoryID`, `Name` |
| `productModelProductDescriptionCulture` | Links product models to descriptions by language | `ProductModelID`, `ProductDescriptionID`, `CultureID` |
| `productDescription` | Product description text | `ProductDescriptionID`, `Description` |
| `salesOrderHeader` | One row per sales order | `SalesOrderID`, `SalesPersonID`, `OrderDate`, `SubTotal`, `CurrencyRateID` |
| `salesOrderDetail` | One row per order line | `SalesOrderID`, `ProductID`, `OrderQty`, `UnitPrice`, `UnitPriceDiscount` |
| `salesPerson` | One row per salesperson | `BusinessEntityID`, `SalesYTD`, `CommissionPct` |
| `currencyRate` | Currency used for converted orders | `CurrencyRateID`, `FromCurrencyCode`, `ToCurrencyCode` |

### How the tables connect

- `product` to `productSubcategory` to `productCategory`, through `ProductSubcategoryID` and `ProductCategoryID`.
- `product` to `productModelProductDescriptionCulture` to `productDescription`, through `ProductModelID` and `ProductDescriptionID`.
- `salesOrderHeader` to `salesOrderDetail`, through `SalesOrderID`, and `salesOrderDetail` to `product`, through `ProductID`.
- `salesOrderHeader` to `salesPerson`, through `SalesPersonID` and `BusinessEntityID`.
- `salesOrderHeader` to `currencyRate`, through `CurrencyRateID`. Orders paid in USD have no rate, so a `LEFT JOIN` is needed to keep them.
- `productReview` to `product`, through `ProductID`.

## Approach

- **Reviews first:** checked whether ratings could measure popularity. Only a handful of products have reviews, so the analysis moved to sales data.
- **Units sold:** summed order quantities (`OrderQty`) by product and by subcategory, because one order line can cover several units.
- **Salesperson performance:** compared the stored year-to-date figure with totals rebuilt from the order records, and recalculated order totals from the order lines to validate the stored `SubTotal`.
- **Currency:** identified the currency of each order, labelled USD orders explicitly, and repeated the sales and commission analysis by currency.

## Key findings

- **Reviews are too thin to use:** only 3 products have reviews (4 reviews in total), so ratings could not be related to sales.
- **Best-selling product:** AWC Logo Cap, with 8,311 units, ahead of the 30 oz water bottle (6,815) and the blue Sport-100 helmet (6,743).
- **Best-selling subcategory:** Road Bikes, with 47,196 of 274,914 units (about 17%), followed by Mountain Bikes (28,321) and Jerseys (22,711).
- **The stored sales figure does not match the orders:** the top five by stored `SalesYTD` (276, 289, 275, 277, 290) differ from the top five by actual 2014 orders (289, 276, 275, 282, 277).
- **Recalculated totals agree with the stored ones:** for the top five, totals rebuilt from the order lines matched the stored `SubTotal` to within rounding.
- **Top salesperson in 2014:** salesperson 289, with about 1.38M in orders (all in CAD, unconverted), on the highest commission rate of 2.0%.
- **Sales rise with commission rate:** across 17 salespeople the correlation is about 0.74. The three salespeople on 0% commission (274, 285, 287) are also the three lowest sellers. This shows an association, not that commission causes higher sales.
- **Currency mix:** orders were placed in AUD, CAD, EUR, GBP and USD. Eleven of the 21 salesperson and currency combinations are in USD, and four salespeople (274, 287, 288, 290) sold in two currencies.

## Author

Naresh. [ADD: LinkedIn URL]
