-- ============================================================
--  Sales BI Dashboard — Core SQL Queries
--  Author: [Your Name]
--  Database: PostgreSQL 15+
-- ============================================================


-- ── 1. MONTHLY KPI VIEW ─────────────────────────────────────
CREATE OR REPLACE VIEW v_monthly_kpis AS
SELECT
  DATE_TRUNC('month', order_date)           AS month,
  COUNT(DISTINCT order_id)                  AS total_orders,
  COUNT(DISTINCT customer_id)               AS active_customers,
  ROUND(SUM(revenue)::NUMERIC, 2)           AS total_revenue,
  ROUND(SUM(profit)::NUMERIC, 2)            AS total_profit,
  ROUND(SUM(profit) / NULLIF(SUM(revenue), 0) * 100, 2) AS profit_margin_pct,
  ROUND(AVG(revenue)::NUMERIC, 2)           AS avg_order_value
FROM sales_fact
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


-- ── 2. REVENUE BY REGION WITH YoY GROWTH ────────────────────
WITH current_year AS (
  SELECT
    region,
    SUM(revenue) AS revenue_2024
  FROM sales_fact
  WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
  GROUP BY region
),
prior_year AS (
  SELECT
    region,
    SUM(revenue) AS revenue_2023
  FROM sales_fact
  WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31'
  GROUP BY region
)
SELECT
  c.region,
  c.revenue_2024,
  p.revenue_2023,
  ROUND((c.revenue_2024 - p.revenue_2023) / NULLIF(p.revenue_2023, 0) * 100, 2) AS yoy_growth_pct
FROM current_year c
LEFT JOIN prior_year p ON c.region = p.region
ORDER BY yoy_growth_pct DESC;


-- ── 3. TOP PRODUCTS BY REVENUE (with rank + margin) ─────────
WITH ranked_products AS (
  SELECT
    product_name,
    product_category,
    SUM(revenue)                AS total_revenue,
    SUM(profit)                 AS total_profit,
    COUNT(DISTINCT order_id)    AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_buyers,
    RANK() OVER (ORDER BY SUM(revenue) DESC) AS revenue_rank
  FROM sales_fact
  GROUP BY product_name, product_category
)
SELECT
  revenue_rank,
  product_name,
  product_category,
  ROUND(total_revenue::NUMERIC, 2)                                     AS total_revenue,
  ROUND(total_profit / NULLIF(total_revenue, 0) * 100, 2)             AS margin_pct,
  total_orders,
  unique_buyers,
  ROUND(total_revenue / NULLIF(total_orders, 0)::NUMERIC, 2)          AS revenue_per_order
FROM ranked_products
ORDER BY revenue_rank
LIMIT 10;


-- ── 4. CUSTOMER PURCHASE BEHAVIOR (Segment Analysis) ────────
SELECT
  customer_segment,
  COUNT(DISTINCT customer_id)                                AS customer_count,
  ROUND(AVG(lifetime_orders)::NUMERIC, 1)                   AS avg_orders,
  ROUND(AVG(lifetime_revenue)::NUMERIC, 2)                  AS avg_ltv,
  ROUND(AVG(avg_order_value)::NUMERIC, 2)                   AS avg_order_value,
  ROUND(SUM(CASE WHEN is_repeat THEN 1 ELSE 0 END)::NUMERIC
    / COUNT(*) * 100, 2)                                    AS repeat_rate_pct
FROM (
  SELECT
    customer_id,
    customer_segment,
    COUNT(order_id)        AS lifetime_orders,
    SUM(revenue)           AS lifetime_revenue,
    AVG(revenue)           AS avg_order_value,
    COUNT(order_id) > 1    AS is_repeat
  FROM sales_fact
  GROUP BY customer_id, customer_segment
) sub
GROUP BY customer_segment
ORDER BY avg_ltv DESC;


-- ── 5. REVENUE VS TARGET (Monthly Gap Analysis) ──────────────
SELECT
  t.month,
  t.revenue_target,
  COALESCE(a.actual_revenue, 0)                              AS actual_revenue,
  ROUND(COALESCE(a.actual_revenue, 0) - t.revenue_target, 2) AS gap,
  ROUND((COALESCE(a.actual_revenue, 0) - t.revenue_target)
    / NULLIF(t.revenue_target, 0) * 100, 2)                 AS gap_pct,
  CASE
    WHEN COALESCE(a.actual_revenue, 0) >= t.revenue_target THEN 'EXCEEDED'
    ELSE 'MISSED'
  END AS status
FROM monthly_targets t
LEFT JOIN (
  SELECT DATE_TRUNC('month', order_date) AS month, SUM(revenue) AS actual_revenue
  FROM sales_fact
  GROUP BY DATE_TRUNC('month', order_date)
) a ON t.month = a.month
ORDER BY t.month;


-- ── 6. DUPLICATE DETECTION (used in cleaning) ────────────────
WITH duplicate_check AS (
  SELECT
    order_id,
    customer_id,
    order_date,
    product_id,
    COUNT(*) OVER (
      PARTITION BY order_id, customer_id, order_date, product_id
    ) AS dup_count
  FROM sales_raw
)
SELECT COUNT(*) AS total_duplicates
FROM duplicate_check
WHERE dup_count > 1;


-- ── 7. ROLLING 3-MONTH GROWTH RATE ───────────────────────────
SELECT
  month,
  total_revenue,
  LAG(total_revenue, 1) OVER (ORDER BY month) AS prev_month_rev,
  ROUND(
    (total_revenue - LAG(total_revenue, 3) OVER (ORDER BY month))
    / NULLIF(LAG(total_revenue, 3) OVER (ORDER BY month), 0) * 100
  , 2) AS rolling_3m_growth_pct
FROM v_monthly_kpis
ORDER BY month;
