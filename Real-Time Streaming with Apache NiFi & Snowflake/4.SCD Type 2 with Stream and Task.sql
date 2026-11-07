CREATE OR REPLACE VIEW v_customer_change_data AS
-- Handle INSERTs: new rows go into history
SELECT customer_id, first_name, last_name, email, street, city, state, country,
    start_time, end_time, is_current, 'I' AS dml_type
FROM (
    SELECT customer_id, first_name, last_name, email, street, city, state, country,
        update_timestamp AS start_time,
        LAG(update_timestamp) OVER (PARTITION BY customer_id ORDER BY update_timestamp DESC) AS end_time_raw,
        CASE WHEN end_time_raw IS NULL THEN '9999-12-31'::TIMESTAMP_NTZ ELSE end_time_raw END AS end_time,
        CASE WHEN end_time_raw IS NULL THEN TRUE ELSE FALSE END AS is_current
    FROM (
        SELECT customer_id, first_name, last_name, email, street, city, state, country, update_timestamp
        FROM customer_table_changes
        WHERE METADATA$ACTION = 'INSERT' AND METADATA$ISUPDATE = 'FALSE'
    )
)
UNION
-- Handle UPDATEs: insert new version + expire old version
SELECT customer_id, first_name, last_name, email, street, city, state, country,
    start_time, end_time, is_current, dml_type
FROM (
    SELECT customer_id, first_name, last_name, email, street, city, state, country,
        update_timestamp AS start_time,
        LAG(update_timestamp) OVER (PARTITION BY customer_id ORDER BY update_timestamp DESC) AS end_time_raw,
        CASE WHEN end_time_raw IS NULL THEN '9999-12-31'::TIMESTAMP_NTZ ELSE end_time_raw END AS end_time,
        CASE WHEN end_time_raw IS NULL THEN TRUE ELSE FALSE END AS is_current,
        dml_type
    FROM (
        SELECT customer_id, first_name, last_name, email, street, city, state, country,
            update_timestamp, 'I' AS dml_type
        FROM customer_table_changes
        WHERE METADATA$ACTION = 'INSERT' AND METADATA$ISUPDATE = 'TRUE'
        UNION
        SELECT customer_id, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
            start_time, 'U' AS dml_type
        FROM customer_history
        WHERE customer_id IN (
            SELECT DISTINCT customer_id FROM customer_table_changes
            WHERE METADATA$ACTION = 'DELETE' AND METADATA$ISUPDATE = 'TRUE'
        ) AND is_current = TRUE
    )
)
UNION
-- Handle DELETEs: expire the current row
SELECT ctc.customer_id, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
    ch.start_time, CURRENT_TIMESTAMP()::TIMESTAMP_NTZ, NULL, 'D'
FROM customer_history ch
INNER JOIN customer_table_changes ctc ON ch.customer_id = ctc.customer_id
WHERE ctc.METADATA$ACTION = 'DELETE' AND ctc.METADATA$ISUPDATE = 'FALSE'
AND ch.is_current = TRUE;




-- Create the SCD Type 2 Task
CREATE OR REPLACE TASK tsk_scd_hist
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = '1 minute'
    ERROR_ON_NONDETERMINISTIC_MERGE = FALSE
AS
MERGE INTO customer_history ch
USING v_customer_change_data ccd
    ON ch.customer_id = ccd.customer_id AND ch.start_time = ccd.start_time
WHEN MATCHED AND ccd.dml_type = 'U' THEN UPDATE
    SET ch.end_time = ccd.end_time, ch.is_current = FALSE
WHEN MATCHED AND ccd.dml_type = 'D' THEN UPDATE
    SET ch.end_time = ccd.end_time, ch.is_current = FALSE
WHEN NOT MATCHED AND ccd.dml_type = 'I' THEN INSERT
    (customer_id, first_name, last_name, email, street, city, state, country,
     start_time, end_time, is_current)
VALUES
    (ccd.customer_id, ccd.first_name, ccd.last_name, ccd.email, ccd.street,
     ccd.city, ccd.state, ccd.country, ccd.start_time, ccd.end_time, ccd.is_current);

-- Start the task
ALTER TASK tsk_scd_hist RESUME;




-- Test It

-- Insert a new customer
INSERT INTO customer VALUES (223136, 'Jessica', 'Arnold', 'tanner39@smith.com',
    '595 Benjamin Forge Suite 124', 'Michaelstad', 'Connecticut', 'Cape Verde',
    CURRENT_TIMESTAMP());

-- Update an existing customer
UPDATE customer SET first_name = 'Jessica', update_timestamp = CURRENT_TIMESTAMP()
WHERE customer_id = 7523;

-- Delete a customer
DELETE FROM customer WHERE customer_id = 136 AND first_name = 'Kim';

-- Wait 1 minute for the task to run, then check history
SELECT * FROM customer_history WHERE customer_id IN (7523, 136, 223136);
SELECT * FROM customer_history WHERE is_current = TRUE;
SELECT * FROM customer_history WHERE is_current = FALSE;
