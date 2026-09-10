#!/usr/bin/env bash

# RetailPulse raw-zone ingestion
#
# This script imports the six SQL Server source tables into matching HDFS raw
# directories. It assumes the existing Hadoop and Sqoop environment has already
# been loaded by the user. Sqoop's -P option prompts for the database password;
# no password is stored in this repository.

set -euo pipefail

JDBC_URL='jdbc:sqlserver://localhost:1433;databaseName=RetailPulse;encrypt=true;trustServerCertificate=true'
JDBC_DRIVER='com.microsoft.sqlserver.jdbc.SQLServerDriver'
SQLSERVER_MANAGER='org.apache.sqoop.manager.SQLServerManager'
DB_USER="${SQLSERVER_USER:-sa}"
RAW_BASE='/retailpulse/raw'

# Empty SQL NULL markers are intentional. Pig's typed load and cleaning stages
# consistently treat these empty delimited fields as missing values.
COMMON_ARGS=(
  --connect "${JDBC_URL}"
  --username "${DB_USER}"
  -P
  --driver "${JDBC_DRIVER}"
  # Keep Sqoop's SQL Server manager when the JDBC driver is named explicitly;
  # the manager supplies the --schema support used by each import below.
  --connection-manager "${SQLSERVER_MANAGER}"
  --as-textfile
  --fields-terminated-by '|'
  --null-string ''
  --null-non-string ''
  --num-mappers 1
  --delete-target-dir
)

# Import dbo.orders into the HDFS raw orders directory.
sqoop import \
  "${COMMON_ARGS[@]}" \
  --table 'orders' \
  --columns 'order_id,customer_id,order_status,order_purchase_timestamp,order_approved_at,order_delivered_carrier_date,order_delivered_customer_date,order_estimated_delivery_date' \
  --target-dir "${RAW_BASE}/orders" \
  -- --schema 'dbo'

# Import dbo.order_items into the HDFS raw order-items directory.
sqoop import \
  "${COMMON_ARGS[@]}" \
  --table 'order_items' \
  --columns 'order_id,order_item_id,product_id,seller_id,shipping_limit_date,price,freight_value' \
  --target-dir "${RAW_BASE}/order_items" \
  -- --schema 'dbo'

# Import dbo.customers into the HDFS raw customers directory.
sqoop import \
  "${COMMON_ARGS[@]}" \
  --table 'customers' \
  --columns 'customer_id,customer_unique_id,customer_zip_code_prefix,customer_city,customer_state' \
  --target-dir "${RAW_BASE}/customers" \
  -- --schema 'dbo'

# Import dbo.products into the HDFS raw products directory.
sqoop import \
  "${COMMON_ARGS[@]}" \
  --table 'products' \
  --columns 'product_id,product_category_name,product_name_lenght,product_description_lenght,product_photos_qty,product_weight_g,product_length_cm,product_height_cm,product_width_cm' \
  --target-dir "${RAW_BASE}/products" \
  -- --schema 'dbo'

# Import dbo.sellers into the HDFS raw sellers directory.
sqoop import \
  "${COMMON_ARGS[@]}" \
  --table 'sellers' \
  --columns 'seller_id,seller_zip_code_prefix,seller_city,seller_state' \
  --target-dir "${RAW_BASE}/sellers" \
  -- --schema 'dbo'

# Import dbo.category_translation into the HDFS raw translation directory.
sqoop import \
  "${COMMON_ARGS[@]}" \
  --table 'category_translation' \
  --columns 'product_category_name,product_category_name_english' \
  --target-dir "${RAW_BASE}/category_translation" \
  -- --schema 'dbo'
