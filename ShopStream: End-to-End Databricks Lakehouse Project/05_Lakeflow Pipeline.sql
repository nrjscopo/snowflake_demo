-- 1. Create the pipeline
-- Go to Jobs & Pipelines and click ETL pipeline under Create new.
-- In the pipeline settings, set the default catalog to shopstream and the default schema to core, and rename the pipeline shopstream_lakeflow. Compute stays serverless.

-- 2. Declare a streaming table
import dlt

@dlt.table(name="pipe_events_bronze", comment="Raw order events from the live feed")
def pipe_events_bronze():
    return (spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "json")
        .load("/Volumes/shopstream/core/events/orders_stream"))

-- 3. Declare a materialized view on top
import dlt
from pyspark.sql.functions import to_date, expr

@dlt.table(name="pipe_daily_revenue", comment="Daily revenue from the live event stream")
def pipe_daily_revenue():
    return (dlt.read("pipe_events_bronze")
        .where("status = 'completed'")
        .groupBy(to_date("event_ts").alias("event_date"))
        .agg(expr("count(*) AS events"), expr("round(sum(quantity * unit_price), 2) AS revenue")))
