-- 1. Peek at the raw file first

-- Peek at the raw orders file before loading anything
SELECT * FROM read_files(
  '/Volumes/shopstream/core/raw/orders_2026_h1.csv',
  format => 'csv',
  header => true
)
LIMIT 10


--- 2. Load orders with COPY INTO
-- Bronze orders: create once, then load with COPY INTO (idempotent)
CREATE TABLE IF NOT EXISTS shopstream.core.bronze_orders;

COPY INTO shopstream.core.bronze_orders
FROM '/Volumes/shopstream/core/raw/orders_2026_h1.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true', 'mergeSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true')

-- 3. Run it again and watch nothing happen

-- 4. Load the two dimension tables
-- Same pattern for the two dimension files
CREATE TABLE IF NOT EXISTS shopstream.core.bronze_customers;

COPY INTO shopstream.core.bronze_customers
FROM '/Volumes/shopstream/core/raw/customers.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true', 'mergeSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true');

CREATE TABLE IF NOT EXISTS shopstream.core.bronze_products;

COPY INTO shopstream.core.bronze_products
FROM '/Volumes/shopstream/core/raw/products.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true', 'mergeSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true');

5. Verify the layer
-- The bronze layer is in. Three tables, raw shapes preserved.
SELECT 'bronze_orders' AS table_name, COUNT(*) AS row_count FROM shopstream.core.bronze_orders
UNION ALL
SELECT 'bronze_customers', COUNT(*) FROM shopstream.core.bronze_customers
UNION ALL
SELECT 'bronze_products', COUNT(*) FROM shopstream.core.bronze_products
