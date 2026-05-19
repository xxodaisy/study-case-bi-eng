# BI Engineer Technical Test

**Dataset:** Brazilian E-Commerce Public Dataset (Olist)  

## Test 1 — Advanced SQL & Data Exploration

### Files
| File | Description |
|---|---|
| `query_partA.sql` | Core queries: A1 Monthly Revenue Trend, A2 Top 10 Product Categories, A3 Customer Cohort Retention |
| `query_partB.sql` | Optimised query |
| `query_beforeop.sql` | Original query before optimisation |
| `query_afterop.sql` | Refactored query after optimisation |

### Query Optimisation Summary (Part B)
- Replaced nested subqueries with CTEs for readability and modularity
- Applied window functions to avoid self joins
- Pre-aggregated data before joining to reduce row count
- Verified with `EXPLAIN ANALYZE`: execution time dropped from **3543ms → 1600ms**

## Test 2 — Business Intelligence Dashboard

### Tool
Apache Superset connected to Brazilian E-Commerce PostgreSQL.

### Dashboard: "E-Commerce Business Overview"
6 charts designed for Senior Manager level users. Full chart explanations in the Medium article.

| # | Chart | Type |
|---|---|---|
| 1 | Summary KPIs (Total Revenue, Orders, Customers, AOV, MoM, Late Delivery Rate) | Big Number |
| 2 | Monthly Revenue Trend | Line Chart |
| 3 | Top 10 Product Categories by Revenue | Bar Chart |
| 4 | Payment Method by Revenue | Bar Chart |
| 5 | Top 10 Late Delivery Rate (%) | Bar Chart |
| 6 | Customer Cohort Retention | Table |

## Test 3 — Analytics Engineering with dbt & Pipeline Design

### ELT Architecture
Raw data from PostgreSQL → loaded as-is → transformed inside warehouse using dbt

### Project Structure
models/

├── staging/       # Cleaning & renaming (view)

├── intermediate/  # Business logic & joins (view)

└── marts/         # Final reporting tables (table)

### Models

#### Staging
| Model | Description |
|---|---|
| `stg_orders` | Renamed columns, casted timestamps |
| `stg_order_items` | Price and freight casted to numeric |
| `stg_customers` | Null-handled city and state |
| `stg_products` | Joined with English category translation |
| `stg_order_reviews` | Rating renamed, is_low_score flag added |

#### Intermediate
| Model | Description |
|---|---|
| `int_orders_enriched` | Joined orders + customers + items + reviews; delivery_delay_days, is_late_delivery |
| `int_seller_metrics` | Per-seller revenue, orders, avg review score, late delivery rate |

#### Mart
| Model | Description |
|---|---|
| `mart_monthly_revenue` | Monthly revenue, order count, MoM growth |
| `mart_customer_segments` | Segmented: new, returning, churned |
| `mart_product_performance` | Products ranked by revenue, units sold, review score |

### Pipeline Design
Full explanation in Medium article. Summary:
- **Loading:** Staging & intermediate as view, mart as table. Schema changes handled via `--full-refresh` and `on_schema_change: sync_all_columns`
- **Orchestration:** Apache Airflow (primary), dbt Cloud (alternative)
- **Data Quality:** `dbt test` with `not_null` and `unique` checks at each layer

### Lineage Graph
[Lineage Graph](http://localhost:8080/#!/source_list/olist?g_v=1&g_i=source:olist%2B) 

### How to Run
```bash
dbt-env\Scripts\Activate.ps1  # activate virtual env
cd olist_analytics
dbt debug                      # test connection
dbt run                        # run all models
dbt test                       # run tests
dbt docs generate && dbt docs serve  # generate docs
```
