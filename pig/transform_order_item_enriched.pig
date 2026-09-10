-- RetailPulse order-item enrichment for Apache Pig 0.17.0.
--
-- Input grain varies by source table. The final output grain is exactly one
-- row for one product item in one customer order. Sqoop writes pipe-delimited
-- text and represents SQL NULL values as empty fields; the typed loads and
-- cleaning logic below consistently handle those fields as missing values.

-- --------------------------------------------------------------------------
-- Stage 1: Load all six raw-zone datasets with explicit source schemas.
-- The product "lenght" fields intentionally preserve Olist's source spelling.
-- --------------------------------------------------------------------------

orders_raw = LOAD '/retailpulse/raw/orders'
    USING PigStorage('|')
    AS (
        order_id:chararray,
        customer_id:chararray,
        order_status:chararray,
        order_purchase_timestamp:chararray,
        order_approved_at:chararray,
        order_delivered_carrier_date:chararray,
        order_delivered_customer_date:chararray,
        order_estimated_delivery_date:chararray
    );

order_items_raw = LOAD '/retailpulse/raw/order_items'
    USING PigStorage('|')
    AS (
        order_id:chararray,
        order_item_id:int,
        product_id:chararray,
        seller_id:chararray,
        shipping_limit_date:chararray,
        price:double,
        freight_value:double
    );

customers_raw = LOAD '/retailpulse/raw/customers'
    USING PigStorage('|')
    AS (
        customer_id:chararray,
        customer_unique_id:chararray,
        customer_zip_code_prefix:chararray,
        customer_city:chararray,
        customer_state:chararray
    );

products_raw = LOAD '/retailpulse/raw/products'
    USING PigStorage('|')
    AS (
        product_id:chararray,
        product_category_name:chararray,
        product_name_lenght:int,
        product_description_lenght:int,
        product_photos_qty:int,
        product_weight_g:double,
        product_length_cm:double,
        product_height_cm:double,
        product_width_cm:double
    );

sellers_raw = LOAD '/retailpulse/raw/sellers'
    USING PigStorage('|')
    AS (
        seller_id:chararray,
        seller_zip_code_prefix:chararray,
        seller_city:chararray,
        seller_state:chararray
    );

category_translation_raw = LOAD '/retailpulse/raw/category_translation'
    USING PigStorage('|')
    AS (
        product_category_name:chararray,
        product_category_name_english:chararray
    );

-- --------------------------------------------------------------------------
-- Stage 2: Clean key text and timestamp text, then filter only unusable rows.
--
-- SQL Server/Sqoop can render a DATETIME2 value with a fractional suffix such
-- as ".0". The source Olist format is yyyy-MM-dd HH:mm:ss, so valid timestamp
-- strings are reduced to their first 19 characters. Missing or malformed text
-- remains null; no placeholder date is invented.
-- --------------------------------------------------------------------------

orders_clean = FOREACH orders_raw GENERATE
    TRIM(order_id) AS order_id:chararray,
    TRIM(customer_id) AS customer_id:chararray,
    LOWER(TRIM(order_status)) AS order_status:chararray,
    (
        (order_purchase_timestamp IS NOT NULL) AND
        (TRIM(order_purchase_timestamp) MATCHES
            '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?')
        ? SUBSTRING(TRIM(order_purchase_timestamp), 0, 19)
        : null
    ) AS order_purchase_timestamp:chararray,
    (
        (order_delivered_customer_date IS NOT NULL) AND
        (TRIM(order_delivered_customer_date) MATCHES
            '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?')
        ? SUBSTRING(TRIM(order_delivered_customer_date), 0, 19)
        : null
    ) AS order_delivered_customer_date:chararray,
    (
        (order_estimated_delivery_date IS NOT NULL) AND
        (TRIM(order_estimated_delivery_date) MATCHES
            '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?')
        ? SUBSTRING(TRIM(order_estimated_delivery_date), 0, 19)
        : null
    ) AS order_estimated_delivery_date:chararray;

orders_valid = FILTER orders_clean BY
    order_id IS NOT NULL AND order_id != '' AND
    customer_id IS NOT NULL AND customer_id != '' AND
    order_status IS NOT NULL AND order_status != '' AND
    order_status != 'canceled' AND
    order_status != 'unavailable';

order_items_clean = FOREACH order_items_raw GENERATE
    TRIM(order_id) AS order_id:chararray,
    order_item_id AS order_item_id:int,
    TRIM(product_id) AS product_id:chararray,
    TRIM(seller_id) AS seller_id:chararray,
    price AS price:double,
    freight_value AS freight_value:double;

order_items_valid = FILTER order_items_clean BY
    order_id IS NOT NULL AND order_id != '' AND
    order_item_id IS NOT NULL AND
    product_id IS NOT NULL AND product_id != '' AND
    seller_id IS NOT NULL AND seller_id != '';

customers_clean = FOREACH customers_raw GENERATE
    TRIM(customer_id) AS customer_id:chararray,
    TRIM(customer_unique_id) AS customer_unique_id:chararray,
    TRIM(customer_city) AS customer_city:chararray,
    TRIM(customer_state) AS customer_state:chararray;

customers_valid = FILTER customers_clean BY
    customer_id IS NOT NULL AND customer_id != '';

products_clean = FOREACH products_raw GENERATE
    TRIM(product_id) AS product_id:chararray,
    TRIM(product_category_name) AS product_category_name:chararray;

products_valid = FILTER products_clean BY
    product_id IS NOT NULL AND product_id != '';

sellers_clean = FOREACH sellers_raw GENERATE
    TRIM(seller_id) AS seller_id:chararray,
    TRIM(seller_city) AS seller_city:chararray,
    TRIM(seller_state) AS seller_state:chararray;

sellers_valid = FILTER sellers_clean BY
    seller_id IS NOT NULL AND seller_id != '';

category_translation_clean = FOREACH category_translation_raw GENERATE
    TRIM(product_category_name) AS product_category_name:chararray,
    TRIM(product_category_name_english) AS product_category_name_english:chararray;

category_translation_valid = FILTER category_translation_clean BY
    product_category_name IS NOT NULL AND product_category_name != '';

-- --------------------------------------------------------------------------
-- Stage 3: Build the order-item grain with the required dimensional joins.
-- Source primary keys make each dimension lookup one-to-one. The category
-- translation is deliberately LEFT OUTER so an untranslated product remains
-- in the fact output with a null English category.
-- --------------------------------------------------------------------------

orders_items_joined = JOIN orders_valid BY order_id,
                           order_items_valid BY order_id;

orders_items = FOREACH orders_items_joined GENERATE
    orders_valid::order_id AS order_id:chararray,
    order_items_valid::order_item_id AS order_item_id:int,
    orders_valid::customer_id AS customer_id:chararray,
    order_items_valid::product_id AS product_id:chararray,
    order_items_valid::seller_id AS seller_id:chararray,
    orders_valid::order_status AS order_status:chararray,
    orders_valid::order_purchase_timestamp AS order_purchase_timestamp:chararray,
    orders_valid::order_delivered_customer_date AS order_delivered_customer_date:chararray,
    orders_valid::order_estimated_delivery_date AS order_estimated_delivery_date:chararray,
    order_items_valid::price AS price:double,
    order_items_valid::freight_value AS freight_value:double;

orders_items_customers_joined = JOIN orders_items BY customer_id,
                                     customers_valid BY customer_id;

orders_items_customers = FOREACH orders_items_customers_joined GENERATE
    orders_items::order_id AS order_id:chararray,
    orders_items::order_item_id AS order_item_id:int,
    orders_items::customer_id AS customer_id:chararray,
    customers_valid::customer_unique_id AS customer_unique_id:chararray,
    customers_valid::customer_city AS customer_city:chararray,
    customers_valid::customer_state AS customer_state:chararray,
    orders_items::product_id AS product_id:chararray,
    orders_items::seller_id AS seller_id:chararray,
    orders_items::order_status AS order_status:chararray,
    orders_items::order_purchase_timestamp AS order_purchase_timestamp:chararray,
    orders_items::order_delivered_customer_date AS order_delivered_customer_date:chararray,
    orders_items::order_estimated_delivery_date AS order_estimated_delivery_date:chararray,
    orders_items::price AS price:double,
    orders_items::freight_value AS freight_value:double;

orders_items_products_joined = JOIN orders_items_customers BY product_id,
                                    products_valid BY product_id;

orders_items_products = FOREACH orders_items_products_joined GENERATE
    orders_items_customers::order_id AS order_id:chararray,
    orders_items_customers::order_item_id AS order_item_id:int,
    orders_items_customers::customer_id AS customer_id:chararray,
    orders_items_customers::customer_unique_id AS customer_unique_id:chararray,
    orders_items_customers::customer_city AS customer_city:chararray,
    orders_items_customers::customer_state AS customer_state:chararray,
    orders_items_customers::product_id AS product_id:chararray,
    products_valid::product_category_name AS product_category_name:chararray,
    orders_items_customers::seller_id AS seller_id:chararray,
    orders_items_customers::order_status AS order_status:chararray,
    orders_items_customers::order_purchase_timestamp AS order_purchase_timestamp:chararray,
    orders_items_customers::order_delivered_customer_date AS order_delivered_customer_date:chararray,
    orders_items_customers::order_estimated_delivery_date AS order_estimated_delivery_date:chararray,
    orders_items_customers::price AS price:double,
    orders_items_customers::freight_value AS freight_value:double;

orders_items_sellers_joined = JOIN orders_items_products BY seller_id,
                                   sellers_valid BY seller_id;

orders_items_sellers = FOREACH orders_items_sellers_joined GENERATE
    orders_items_products::order_id AS order_id:chararray,
    orders_items_products::order_item_id AS order_item_id:int,
    orders_items_products::customer_id AS customer_id:chararray,
    orders_items_products::customer_unique_id AS customer_unique_id:chararray,
    orders_items_products::customer_city AS customer_city:chararray,
    orders_items_products::customer_state AS customer_state:chararray,
    orders_items_products::product_id AS product_id:chararray,
    orders_items_products::product_category_name AS product_category_name:chararray,
    orders_items_products::seller_id AS seller_id:chararray,
    sellers_valid::seller_city AS seller_city:chararray,
    sellers_valid::seller_state AS seller_state:chararray,
    orders_items_products::order_status AS order_status:chararray,
    orders_items_products::order_purchase_timestamp AS order_purchase_timestamp:chararray,
    orders_items_products::order_delivered_customer_date AS order_delivered_customer_date:chararray,
    orders_items_products::order_estimated_delivery_date AS order_estimated_delivery_date:chararray,
    orders_items_products::price AS price:double,
    orders_items_products::freight_value AS freight_value:double;

orders_items_translated_joined = JOIN orders_items_sellers BY product_category_name LEFT OUTER,
                                      category_translation_valid BY product_category_name;

-- --------------------------------------------------------------------------
-- Stage 4: Derive financial and delivery fields.
--
-- DaysBetween returns whole elapsed days, so delay_days can be zero even when
-- delivery occurs later than the estimated timestamp by less than 24 hours.
-- is_late therefore compares the two valid timestamps in milliseconds. All
-- delivery metrics stay null when their required dates are unavailable.
-- --------------------------------------------------------------------------

enriched_base = FOREACH orders_items_translated_joined GENERATE
    orders_items_sellers::order_id AS order_id:chararray,
    orders_items_sellers::order_item_id AS order_item_id:int,
    orders_items_sellers::customer_id AS customer_id:chararray,
    orders_items_sellers::customer_unique_id AS customer_unique_id:chararray,
    orders_items_sellers::customer_city AS customer_city:chararray,
    orders_items_sellers::customer_state AS customer_state:chararray,
    orders_items_sellers::product_id AS product_id:chararray,
    orders_items_sellers::product_category_name AS product_category_name:chararray,
    category_translation_valid::product_category_name_english AS product_category_english:chararray,
    orders_items_sellers::seller_id AS seller_id:chararray,
    orders_items_sellers::seller_city AS seller_city:chararray,
    orders_items_sellers::seller_state AS seller_state:chararray,
    orders_items_sellers::order_status AS order_status:chararray,
    orders_items_sellers::order_purchase_timestamp AS order_purchase_timestamp:chararray,
    orders_items_sellers::order_delivered_customer_date AS order_delivered_customer_date:chararray,
    orders_items_sellers::order_estimated_delivery_date AS order_estimated_delivery_date:chararray,
    orders_items_sellers::price AS price:double,
    orders_items_sellers::freight_value AS freight_value:double,
    (
        orders_items_sellers::price IS NULL OR
        orders_items_sellers::freight_value IS NULL
        ? null
        : orders_items_sellers::price + orders_items_sellers::freight_value
    ) AS item_total_value:double;

enriched_dates = FOREACH enriched_base GENERATE
    order_id,
    order_item_id,
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state,
    product_id,
    product_category_name,
    product_category_english,
    seller_id,
    seller_city,
    seller_state,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    price,
    freight_value,
    item_total_value,
    (
        order_purchase_timestamp IS NULL
        ? null
        : ToDate(order_purchase_timestamp, 'yyyy-MM-dd HH:mm:ss')
    ) AS purchase_datetime,
    (
        order_delivered_customer_date IS NULL
        ? null
        : ToDate(order_delivered_customer_date, 'yyyy-MM-dd HH:mm:ss')
    ) AS delivered_datetime,
    (
        order_estimated_delivery_date IS NULL
        ? null
        : ToDate(order_estimated_delivery_date, 'yyyy-MM-dd HH:mm:ss')
    ) AS estimated_datetime;

enriched_metrics = FOREACH enriched_dates GENERATE
    order_id,
    order_item_id,
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state,
    product_id,
    product_category_name,
    product_category_english,
    seller_id,
    seller_city,
    seller_state,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    price,
    freight_value,
    item_total_value,
    (
        delivered_datetime IS NULL OR purchase_datetime IS NULL
        ? null
        : DaysBetween(delivered_datetime, purchase_datetime)
    ) AS delivery_days:long,
    (
        delivered_datetime IS NULL OR estimated_datetime IS NULL
        ? null
        : DaysBetween(delivered_datetime, estimated_datetime)
    ) AS delay_days:long,
    (
        delivered_datetime IS NULL OR estimated_datetime IS NULL
        ? null
        : (
            ToMilliSeconds(delivered_datetime) > ToMilliSeconds(estimated_datetime)
            ? 1
            : 0
        )
    ) AS is_late:int;

order_item_enriched = FOREACH enriched_metrics GENERATE
    order_id AS order_id:chararray,
    order_item_id AS order_item_id:int,
    customer_id AS customer_id:chararray,
    customer_unique_id AS customer_unique_id:chararray,
    customer_city AS customer_city:chararray,
    customer_state AS customer_state:chararray,
    product_id AS product_id:chararray,
    product_category_name AS product_category_name:chararray,
    product_category_english AS product_category_english:chararray,
    seller_id AS seller_id:chararray,
    seller_city AS seller_city:chararray,
    seller_state AS seller_state:chararray,
    order_status AS order_status:chararray,
    order_purchase_timestamp AS order_purchase_timestamp:chararray,
    order_delivered_customer_date AS order_delivered_customer_date:chararray,
    order_estimated_delivery_date AS order_estimated_delivery_date:chararray,
    price AS price:double,
    freight_value AS freight_value:double,
    item_total_value AS item_total_value:double,
    delivery_days AS delivery_days:long,
    delay_days AS delay_days:long,
    is_late AS is_late:int;

-- --------------------------------------------------------------------------
-- Stage 5: Replace the previous processed output and store pipe-delimited text.
-- rmf is a Pig/Grunt command, making this batch job safe to rerun.
-- --------------------------------------------------------------------------

rmf /retailpulse/processed/order_item_enriched;

STORE order_item_enriched
    INTO '/retailpulse/processed/order_item_enriched'
    USING PigStorage('|');
