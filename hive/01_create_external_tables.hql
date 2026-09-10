-- RetailPulse Hive analytical layer
--
-- This script creates metadata only for the Pig output. The EXTERNAL table
-- points at the existing HDFS processed-zone files; it does not copy them.

CREATE DATABASE IF NOT EXISTS retailpulse;

USE retailpulse;

-- Keep execution aligned with the coursework's tested Hive-on-MapReduce setup.
SET hive.execution.engine=mr;

-- Dropping an EXTERNAL table removes only its Hive metadata. The processed
-- files under /retailpulse/processed/order_item_enriched remain in HDFS.
DROP TABLE IF EXISTS fact_order_item;

CREATE EXTERNAL TABLE fact_order_item (
    order_id                       STRING,
    order_item_id                  INT,
    customer_id                    STRING,
    customer_unique_id             STRING,
    customer_city                  STRING,
    customer_state                 STRING,
    product_id                     STRING,
    product_category_name          STRING,
    product_category_english       STRING,
    seller_id                      STRING,
    seller_city                    STRING,
    seller_state                   STRING,
    order_status                   STRING,
    order_purchase_timestamp       TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP,
    price                          DOUBLE,
    freight_value                  DOUBLE,
    item_total_value               DOUBLE,
    delivery_days                  BIGINT,
    delay_days                     BIGINT,
    is_late                        INT
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
    'field.delim'               = '|',
    'serialization.format'      = '|',
    'serialization.null.format' = ''
)
STORED AS TEXTFILE
LOCATION '/retailpulse/processed/order_item_enriched';

-- Pig writes timestamps in the Olist format yyyy-MM-dd HH:mm:ss, which Hive
-- 2.3.9 can deserialize as TIMESTAMP. Empty Pig fields are interpreted as NULL
-- by the serialization.null.format setting above.
