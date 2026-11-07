-- FILTER
-- Problem 1: the source system logs statuses in two casings
SELECT status, COUNT(*) AS row_count
FROM shopstream.core.bronze_orders
GROUP BY status
ORDER BY row_count DESC

-- Problem 2: double-fired order lines and impossible quantities
SELECT
  (SELECT COUNT(*) FROM (
    SELECT order_line_id FROM shopstream.core.bronze_orders
    GROUP BY order_line_id HAVING COUNT(*) > 1
  )) AS duplicated_line_ids,
  (SELECT COUNT(*) FROM shopstream.core.bronze_orders WHERE quantity <= 0) AS bad_quantity_rows


-- 2. Build silver_orders
-- silver_orders: dedup double-fires, drop impossible rows, normalize, type, derive
CREATE OR REPLACE TABLE shopstream.core.silver_orders AS
WITH deduped AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY order_line_id ORDER BY order_ts) AS rn
  FROM shopstream.core.bronze_orders
)
SELECT
  order_line_id,
  order_id,
  customer_id,
  product_id,
  CAST(quantity AS INT) AS quantity,
  CAST(unit_price AS DOUBLE) AS unit_price,
  ROUND(quantity * unit_price, 2) AS line_revenue,
  CAST(order_ts AS TIMESTAMP) AS order_ts,
  LOWER(status) AS status,
  NULLIF(coupon_code, '') AS coupon_code
FROM deduped
WHERE rn = 1
  AND quantity > 0;

SELECT COUNT(*) AS silver_rows FROM shopstream.core.silver_orders


-- Dimensions need a lighter touch: types + a helpful derived column
CREATE OR REPLACE TABLE shopstream.core.silver_customers AS
SELECT
  customer_id,
  name,
  email,
  city,
  country,
  CAST(signup_date AS DATE) AS signup_date,
  signup_channel
FROM shopstream.core.bronze_customers;

CREATE OR REPLACE TABLE shopstream.core.silver_products AS
SELECT
  product_id,
  product_name,
  category,
  CAST(unit_price AS DOUBLE) AS unit_price,
  CAST(unit_cost AS DOUBLE) AS unit_cost,
  ROUND(unit_price - unit_cost, 2) AS unit_margin
FROM shopstream.core.bronze_products;


-- Delta keeps a transaction log for every table. Look:
DESCRIBE HISTORY shopstream.core.silver_orders


--removing cancelled orders
-- Business rule: cancelled orders don't belong in silver.
-- Delta DML makes this a one-liner, and time travel keeps the audit trail.
DELETE FROM shopstream.core.silver_orders WHERE status = 'cancelled';

SELECT
  (SELECT COUNT(*) FROM shopstream.core.silver_orders) AS rows_now,
  (SELECT COUNT(*) FROM shopstream.core.silver_orders VERSION AS OF 0) AS rows_before_delete

