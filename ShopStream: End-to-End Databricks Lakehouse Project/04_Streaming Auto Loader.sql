-- 1. Ingest with Auto Loader


--# Auto Loader: pick up every new event file exactly once
EVENTS_PATH = "/Volumes/shopstream/core/events/orders_stream"
CHECKPOINT = "/Volumes/shopstream/core/events/_checkpoints/bronze_orders_stream"

stream = (spark.readStream
    .format("cloudFiles")
    .option("cloudFiles.format", "json")
    .option("cloudFiles.schemaLocation", CHECKPOINT)
    .load(EVENTS_PATH))

(stream.writeStream
    .option("checkpointLocation", CHECKPOINT)
    .trigger(availableNow=True)
    .toTable("shopstream.core.bronze_orders_stream")
    .awaitTermination())


--Count what landed:
display(spark.sql("SELECT COUNT(*) AS events_ingested FROM shopstream.core.bronze_orders_stream"))

