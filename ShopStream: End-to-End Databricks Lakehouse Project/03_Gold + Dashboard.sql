--Silver answers "what happened, cleanly". Gold answers the questions people actually ask: how much did we sell yesterday, which categories make money, who are our best customers. Gold tables are small, aggregated, and shaped for exactly one audience: whoever reads the dashboard.

-- 1. Daily revenue
-- Gold #1: daily revenue, completed orders only, one row per day
CREATE OR REPLACE TABLE shopstream.core.gold_daily_revenue AS
SELECT
  DATE(order_ts) AS order_date,
  COUNT(DISTINCT order_id) AS orders,
  SUM(quantity) AS units_sold,
  ROUND(SUM(line_revenue), 2) AS revenue
FROM shopstream.core.silver_orders
WHERE status = 'completed'
GROUP BY DATE(order_ts);

SELECT * FROM shopstream.core.gold_daily_revenue ORDER BY order_date LIMIT 7


2. Category performance
-- Gold #2: category performance, what actually makes money
CREATE OR REPLACE TABLE shopstream.core.gold_category_performance AS
SELECT
  p.category,
  COUNT(DISTINCT o.order_id) AS orders,
  SUM(o.quantity) AS units_sold,
  ROUND(SUM(o.line_revenue), 2) AS revenue,
  ROUND(SUM(o.quantity * p.unit_margin), 2) AS gross_margin
FROM shopstream.core.silver_orders o
JOIN shopstream.core.silver_products p USING (product_id)
WHERE o.status = 'completed'
GROUP BY p.category;

SELECT * FROM shopstream.core.gold_category_performance ORDER BY revenue DESC


-- 3. Customer lifetime value
-- Gold #3: customer lifetime value, who the best customers are
CREATE OR REPLACE TABLE shopstream.core.gold_customer_ltv AS
SELECT
  c.customer_id,
  c.name,
  c.country,
  c.signup_channel,
  COUNT(DISTINCT o.order_id) AS lifetime_orders,
  ROUND(SUM(o.line_revenue), 2) AS lifetime_revenue
FROM shopstream.core.silver_orders o
JOIN shopstream.core.silver_customers c USING (customer_id)
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name, c.country, c.signup_channel;

SELECT * FROM shopstream.core.gold_customer_ltv ORDER BY lifetime_revenue DESC LIMIT 10


-- 4. Build the dashboard    --------  ShopStream Sales
--1 Click New → Dashboard and rename it ShopStream Sales (double-click the title).
--2 Open the Data tab and click Add data. Search for gold_ and add shopstream.core.gold_category_performance, then repeat for shopstream.core.gold_daily_revenue.
-- publish it