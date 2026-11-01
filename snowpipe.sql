-- continuous data ingestion to snowflake 
-- s3/adls/gcp--event notification srvice trigger---snowpipe receive notification--copy into---data load to table 


create or replace database Session_pipe;
use Session_pipe;
create or replace schema Session_pipe.sesssPip_schem;
use Session_pipe.sesssPip_schem;


CREATE OR REPLACE TABLE fact_retail_sales (
    invoice NUMBER,
    stockcode NUMBER,
    description STRING,
    quantity INT,
    invoicedate DATE,
    price INT,
    customer_id INT,
    country STRING
);

create or replace file format stock_csv_snoepipe
    TYPE= CSV
    SKIP_HEADER=1
FIELD_DELIMITER=',';

CREATE OR REPLACE STORAGE INTEGRATION azure_blob_integration_snowpipe
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'AZURE'
  ENABLED = TRUE
  AZURE_TENANT_ID = 'tenant_id' -- Replace with your actual Azure Tenant ID (GUID)
  STORAGE_ALLOWED_LOCATIONS = ('azure://mission100adlsadf.blob.core.windows.net/landingzone/');

   CREATE OR REPLACE STAGE AZURE_STAGE_with_integration_snopipe
    STORAGE_INTEGRATION = azure_blob_integration_snowpipe
    URL = 'azure://mission100adlsadf.blob.core.windows.net/landingzone/'
    FILE_FORMAT = stock_csv_snoepipe; 

list @AZURE_STAGE_with_integration_snopipe;


USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE NOTIFICATION INTEGRATION snopipe_integration
    TYPE = QUEUE
    ENABLED = TRUE
    NOTIFICATION_PROVIDER = 'AZURE_STORAGE_QUEUE'
    AZURE_TENANT_ID = 'tenant_id' -- Step 1: Add your Tenant ID here
    AZURE_STORAGE_QUEUE_PRIMARY_URI = 'https://mission100adlsadf.queue.core.windows.net/snowpipequeue'; -- Step 2: Add your Queue URL here


describe integration snopipe_integration;


--- in aws use sqs in bw notification and snowflake 

CREATE OR REPLACE PIPE salespipe
AUTO_INGEST = TRUE
integration=snopipe_integration
AS 
COPY INTO fact_retail_sales -- Pointed to staging table instead of the Fact table
FROM @AZURE_STAGE_with_integration_snopipe
FILE_FORMAT = (FORMAT_NAME = Session_pipe.sesssPip_schem.stock_csv_snoepipe);

SHOW PIPES;


SELECT SYSTEM$PIPE_STATUS('salespipe');

SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
   TABLE_NAME => 'fact_retail_sales', 
   START_TIME => DATEADD(hours, -1, CURRENT_TIMESTAMP())
));


ALTER FILE FORMAT SESSION_PIPE.SESSSPIP_SCHEM.stock_csv_snoepipe SET 
    DATE_FORMAT = 'DD-MM-YYYY'
    TIMESTAMP_FORMAT = 'AUTO';

    ALTER PIPE SESSION_PIPE.SESSSPIP_SCHEM.salespipe REFRESH;



select * from fact_retail_sales; 