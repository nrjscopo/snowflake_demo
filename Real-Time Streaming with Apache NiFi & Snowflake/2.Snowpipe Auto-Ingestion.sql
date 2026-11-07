-- 
CREATE OR REPLACE STAGE SCD_DEMO.SCD2.customer_ext_stage
    url='s3://dw-snowflake-course-darshil/stream_data'
    credentials=(aws_key_id='' aws_secret_key='');

CREATE OR REPLACE FILE FORMAT SCD_DEMO.SCD2.CSV
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1;

CREATE OR REPLACE PIPE customer_s3_pipe
    AUTO_INGEST = TRUE
    AS
    COPY INTO customer_raw
    FROM @customer_ext_stage
    FILE_FORMAT = CSV;


SHOW PIPES;
SELECT SYSTEM$PIPE_STATUS('customer_s3_pipe');
SELECT COUNT(*) FROM customer_raw;
