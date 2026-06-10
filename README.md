# Sales Funnel Data Warehouse

**Author:** Zaki Abiyu Aqilah   
**Tools:** SQL (MySQL), CSV Data Sources  
**Goal:** Build a data warehouse from raw sales funnel, product, and transaction data for integrated business analysis

---

## Project Overview

This project implements a **complete ETL pipeline using SQL** to clean, transform, and integrate three disparate data sources into a single data warehouse table (`f_summary_transaction`). The final output enables analysis of sales performance, product profitability, and funnel conversion metrics (view → click → add to cart → purchase).

**Key Outcomes:**
- **Cleaned 3 raw tables** (product, funnel, transaction) – handled duplicate products, NULL transaction IDs, and inconsistent date formats
- **Integrated data** across all sources using `JOIN` and `CTE` (Common Table Expressions)
- **Produced a summary table** with 10+ business metrics including total revenue, profit, and funnel counts per product per day

---

## Dataset

The repository contains three CSV files representing different aspects of the business:

| File | Description | Key Columns | Row Count |
|------|-------------|-------------|------------|
| `tbl_product.csv` | Product master data | product_id, product_name, product_category, product_cost, product_price | 35 products (duplicates exist) |
| `tbl_funnel.csv` | Daily marketing funnel metrics | date, product_id, view, click, add_to_cart, purchase | ~1,800+ rows (Jan 2024 – Sep 2025) |
| `tbl_transaction.csv` | Individual sales transactions | trx_id, product_id, trx_date, units | ~17,000+ transactions |

### Data Quality Issues Addressed
- **Product table**: `product_cost` and `product_price` contained `'IDR '` prefix → removed and cast to numeric. Duplicate rows (`DQProduk-015`, `DQProduk-035`) were deduplicated.
- **Funnel & Transaction tables**: Date columns stored as `ddmmyyyy` (e.g., `1012024` for 1 Jan 2024) → converted to proper `DATE` type using `STR_TO_DATE(LPAD(...), '%d%m%Y')`.
- **Transaction table**: One record had `NULL` as `trx_id` – removed during cleaning.

---

## Data Warehouse Schema

The final integrated table `f_summary_transaction` contains the following columns:

| Column | Source | Description |
|--------|--------|-------------|
| `trx_date` | Funnel / Transaction | Business date (DATE type) |
| `product_id` | All tables | Product identifier |
| `product_name` | Product | Product name |
| `product_category` | Product | Merchandise, Elektronik, Alat Tulis, etc. |
| `total_units` | Transaction | Total quantity sold (sum of units) |
| `product_cost` | Product | Cost per unit (numeric, IDR) |
| `product_price` | Product | Selling price per unit (numeric, IDR) |
| `total_revenue` | Derived | total_units * product_price |
| `total_profit` | Derived | total_units * (product_price - product_cost) |
| `total_purchase` | Funnel | Number of purchase events |
| `total_add_to_cart` | Funnel | Number of add-to-cart events |
| `total_click` | Funnel | Number of product clicks |
| `total_view` | Funnel | Number of product views |

---

## SQL Process (ETL Pipeline)

All SQL scripts below are located in the [`sript/`](script/).

### 1. Create Raw Tables 
```sql
CREATE TABLE tbl_product_raw ( ... );
CREATE TABLE tbl_funnel_raw ( ... );
CREATE TABLE tbl_transaction_raw ( ... );
```

### 2. Clean Product Data 

Remove `'IDR '` from cost/price, cast to `DECIMAL`, deduplicate.

```sql
SELECT DISTINCT
    product_id,
    CAST(REPLACE(product_cost, 'IDR ', '') AS DECIMAL(10,2)) AS product_cost,
    ...
```

### 3. Clean Funnel & Transaction Dates 

Convert `ddmmyyyy` string to `DATE`.

```sql
STR_TO_DATE(LPAD(`date`, 8, '0'), '%d%m%Y') AS trx_date
```

### 4. Create DWH Tables 

Store cleaned data into tbl_dwh_product, tbl_dwh_funnel, tbl_dwh_transaction.

### 5. Integrate Data 

Use CTEs to aggregate transactions and funnel metrics, then `LEFT JOIN` and `INNER JOIN` with product master.

```sql
WITH transaction_agg AS (...),
     funnel_agg AS (...)
SELECT ...
FROM funnel_agg f
LEFT JOIN transaction_agg t ON ...
INNER JOIN tbl_dwh_product p ON ...
```

### 6. Create Summary Table 

Persist the integrated result into `f_summary_transaction` for fast querying.

> **Full output** can be seen in `/output`.
