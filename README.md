# 📊 Sales Data Analysis & Business Intelligence Dashboard
### End-to-End Data Analytics Project | 2024–2025

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.11-3572A5?style=for-the-badge&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/SQL-PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black"/>
  <img src="https://img.shields.io/badge/Excel-1D7140?style=for-the-badge&logo=microsoftexcel&logoColor=white"/>
  <img src="https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white"/>
</p>

<p align="center">
  <a href="https://YOUR-USERNAME.github.io/sales-bi-dashboard"><strong>🔗 Live Dashboard Demo →</strong></a>
</p>

---

## 🎯 Project Overview

A full-cycle data analytics project analyzing **15 months of sales data** (Jan 2024 – Mar 2025) across multiple regions and product lines. The goal was to surface actionable business intelligence — identifying revenue trends, top-performing products, regional growth patterns, and customer purchasing behavior — using a modern analytics stack.

> **Dataset**: 142,830 transaction records · 5 source tables · 2,840 unique SKUs · 4 global regions

---

## 📈 Key Results & Business Impact

| KPI | Value | Change |
|-----|-------|--------|
| Total Revenue | **$14.9M** | ↑ +18.4% YoY |
| Profit Margin | **31.4%** | ↑ +3.2pp vs 2023 |
| Monthly Growth Rate | **6.7%** | ↑ 3-month rolling avg |
| Active Customers | **8,240** | ↑ +1,240 new |
| Top Region (APAC) | **$3.3M** | ↑ +31% YoY |
| Q4 vs Target | **+23%** | Exceeded every month |

---

## 🗂️ Repository Structure

```
sales-bi-dashboard/
│
├── 📂 data/
│   ├── raw/                    # Original source CSVs (gitignored)
│   └── processed/              # Cleaned datasets output by pipeline
│
├── 📂 notebooks/
│   ├── 01_data_cleaning.ipynb        # ETL + transformation pipeline
│   ├── 02_exploratory_analysis.ipynb # EDA, distributions, correlations
│   ├── 03_revenue_trends.ipynb       # Time-series analysis
│   └── 04_customer_behavior.ipynb    # Segmentation & cohort analysis
│
├── 📂 sql/
│   ├── create_tables.sql       # Schema definition
│   ├── revenue_by_region.sql   # Regional aggregations
│   ├── top_products.sql        # Product ranking queries
│   └── monthly_kpis.sql        # KPI calculation queries
│
├── 📂 dashboard/
│   └── index.html              # Interactive BI dashboard (this file!)
│
├── 📂 reports/
│   └── sales_analysis_2024.pdf # Executive summary report
│
├── requirements.txt
└── README.md
```

---

## 🔧 Technical Approach

### 1. Data Ingestion & Cleaning (Python / Pandas)
- Loaded 5 CSV source tables into a unified Pandas DataFrame
- Removed **3,412 duplicate rows** using `DataFrame.drop_duplicates()` + custom key hashing
- Imputed **1,180 null values** using median strategy for numerical fields and forward-fill for date-sorted categorical fields
- Capped **127 outliers** using the IQR (Interquartile Range) method on `revenue` and `quantity` columns
- Standardized date formats, currency symbols, and categorical encodings

```python
# Outlier capping with IQR
Q1 = df['revenue'].quantile(0.25)
Q3 = df['revenue'].quantile(0.75)
IQR = Q3 - Q1
df['revenue'] = df['revenue'].clip(Q1 - 1.5*IQR, Q3 + 1.5*IQR)
```

### 2. SQL Analysis (PostgreSQL)
- Wrote optimized queries using **CTEs**, **window functions**, and **GROUP BY ROLLUP** for hierarchical aggregations
- Built monthly KPI views (`CREATE VIEW`) consumed directly by Power BI

```sql
-- Top products by revenue with running total
WITH ranked_products AS (
  SELECT
    product_name,
    SUM(revenue)   AS total_revenue,
    SUM(profit)    AS total_profit,
    COUNT(DISTINCT customer_id) AS unique_buyers,
    RANK() OVER (ORDER BY SUM(revenue) DESC) AS revenue_rank
  FROM sales_fact
  GROUP BY product_name
)
SELECT *, ROUND(total_profit / total_revenue * 100, 2) AS margin_pct
FROM ranked_products
ORDER BY revenue_rank;
```

### 3. Power BI Dashboard
- Connected Power BI directly to PostgreSQL views via DirectQuery
- Built calculated measures in **DAX** for YoY growth, rolling averages, and margin %
- Created **slicers** for Region, Product Category, and Date Range
- Published to Power BI Service for stakeholder sharing

### 4. Excel Analysis
- Built **Pivot Tables** summarizing revenue by region × product × month
- Created dynamic charts (waterfall, combo bar+line) for executive presentations
- Used **VLOOKUP / XLOOKUP** for customer mapping and **SUMIFS** for conditional KPI rollups

---

## 📊 Dashboard Features

The `dashboard/index.html` is a standalone interactive dashboard replicating the Power BI visuals:

- **KPI Cards** — animated counters for Revenue, Margin, Growth, Customers
- **Trend Chart** — monthly revenue (bar) + profit (line overlay) for 2024
- **Regional Donut** — revenue split with YoY change indicators
- **Top Products** — ranked horizontal bars with $ values
- **Revenue vs Target** — combo chart, green bars = exceeded, blue = under
- **Customer Radar** — purchase behavior across Enterprise / SMB / Startup segments
- **Data Pipeline Panel** — completeness visualization with cleaning stats

---

## 🚀 How to Run

### Python notebooks
```bash
pip install -r requirements.txt
jupyter notebook notebooks/
```

### SQL scripts
```bash
psql -U your_user -d sales_db -f sql/create_tables.sql
psql -U your_user -d sales_db -f sql/monthly_kpis.sql
```

### Dashboard (no server needed)
```bash
# Just open in browser:
open dashboard/index.html
```

---

## 📦 Requirements

```
pandas==2.2.0
numpy==1.26.4
matplotlib==3.8.2
seaborn==0.13.2
sqlalchemy==2.0.27
psycopg2-binary==2.9.9
jupyter==1.0.0
openpyxl==3.1.2
```

---

## 💡 Key Insights Discovered

1. **Q4 surge** — October–December 2024 consistently exceeded targets by 15–28%, driven by enterprise contract renewals
2. **APAC fastest growing** — Asia-Pacific at +31% YoY was the highest growth region; EU and NA were steady
3. **Enterprise Suite dominance** — Top product ($2.34M) drove 23% of total revenue alone
4. **High repeat rate** — 63.2% of customers made repeat purchases; churn at 8.7% (below industry avg of 12%)
5. **Profit margin expansion** — Margin improved from 28.2% → 31.4% after shifting product mix toward higher-margin SaaS tiers

---

## 👤 Author

**[Your Name]**
Data Analyst | Python · SQL · Power BI · Excel

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat&logo=linkedin)](https://linkedin.com/in/your-profile)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=flat&logo=github)](https://github.com/your-username)

---

*This project demonstrates end-to-end data analytics skills: data ingestion, cleaning, SQL analysis, KPI development, visualization, and business storytelling.*
