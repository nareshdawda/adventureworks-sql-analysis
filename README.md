# AdventureWorks SQL Analysis

SQL analysis of the AdventureWorks sample database, covering product reviews, product sales, salesperson performance, commission rates and order currencies. The project is a set of nine exercises, each building on the last, using joins, aggregation, common table expressions (CTEs) and validation checks.

## Business questions

1. Which products are rated highest, and is there enough review data to use ratings as a measure of popularity?
2. Which products and product subcategories sell the most (in units)?
3. Who are the top salespeople, and does commission rate relate to sales?
4. Does the answer change when the currency of each order is taken into account?

## Dataset

- AdventureWorks sample database, supplied with a data dictionary that documents the full schema (71 tables).
- The queries use 10 of those tables: `product`, `productReview`, `productModelProductDescriptionCulture`, `productDescription`, `productCategory`, `productSubcategory`, `salesOrderDetail`, `salesOrderHeader`, `salesPerson` and `currencyRate`.
- The database and the data dictionary are not included in this repository.

## Repository contents

| File | Description |
|---|---|
| `adventureworks_sql_project.sql` | All queries in exercise order, each with a comment explaining why it was run |
| `README.md` | This file |

## What each exercise does

| Exercise | What it does |
|---|---|
| 1 | Ranks products by average review rating, with the number of reviews behind each average |
| 2 | Finds the top 10 best-selling products, using English product descriptions |
| 3 | Compares average list price and total units sold for each product subcategory |
| 4 | Lists the top 5 salespeople by the stored year-to-date sales figure (`SalesYTD`) |
| 5 | Rebuilds the top 5 from 2014 order records (`SubTotal`) instead of the stored figure |
| 6 | Recalculates order totals from the order lines to validate `SubTotal`, then ranks 2014 salespeople on the recalculated totals |
| 7 | Joins 2014 sales to each salesperson's commission rate to test for a relationship |
| 8 | Identifies the currency of each order, using a `LEFT JOIN` and a `CASE` expression to label USD orders |
| 9 | Repeats the sales and commission analysis split by currency |

## SQL techniques demonstrated

- `INNER JOIN` and `LEFT JOIN` across multiple tables
- Aggregation (`SUM`, `AVG`, `COUNT`) with `GROUP BY`
- Common table expressions, including several chained in one query
- `CASE` expressions to replace `NULL` values with meaningful labels
- Date-range filtering and handling of `NULL` and empty values
- Sorting and `LIMIT` for top-N results
- Validating a derived value by recalculating it from its source rows

## Key findings

<!-- Fill in each [ADD: ...] from your own query results, then delete any line you cannot support. Delete this comment before you finish. -->

- **Product reviews:** only a handful of products have reviews, which is too few to relate ratings to sales, so the analysis moves to sales data.
- **Best-selling product (Exercise 2):** [ADD: product name and units sold]
- **Top subcategory by units sold (Exercise 3):** [ADD: subcategory name and units sold]
- **Top salesperson in 2014 (Exercises 6 and 7):** [ADD: salesperson ID and total, noting the currency]
- **Sales against commission rate (Exercise 7):** [ADD: correlation value and what it suggests]
- **Order totals validation (Exercise 6):** [ADD: whether recalculated totals matched the stored `SubTotal`]

## Caveats

- The 2014 filters cover only the months present in the data.
- Per the project brief, order amounts are in each order's local currency and are not converted to USD. The totals in Exercises 5 to 7 therefore mix currencies. Exercise 9 groups by currency so that totals are compared within one currency.
- The number of salespeople is small, so any correlation is indicative only, and it does not show that commission causes higher sales.
- Only a few products have reviews.

## How to run

1. Load the AdventureWorks sample database into SQLite (the database file is not included here).
2. Open `adventureworks_sql_project.sql` in any SQLite client.
3. Run the queries in order. Each one is separated by a comment explaining its purpose. Table names are used without a schema prefix.

## Author

Naresh. https://www.linkedin.com/in/nareshdawda/

