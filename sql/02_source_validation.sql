/*
    RetailPulse source-data validation
    Target platform: Microsoft SQL Server 2022

    Run this read-only script after importing the six Olist CSV files with
    DBeaver and before running the Sqoop ingestion. The script does not insert,
    update, delete, truncate, or otherwise modify source data.
*/

USE [RetailPulse];
GO

SET NOCOUNT ON;
GO

/* -------------------------------------------------------------------------
   1. Row count for every source table
   ------------------------------------------------------------------------- */
SELECT source_table, row_count
FROM
(
    SELECT 1 AS display_order, N'dbo.orders' AS source_table,
           COUNT_BIG(*) AS row_count
    FROM dbo.orders

    UNION ALL
    SELECT 2, N'dbo.order_items', COUNT_BIG(*)
    FROM dbo.order_items

    UNION ALL
    SELECT 3, N'dbo.customers', COUNT_BIG(*)
    FROM dbo.customers

    UNION ALL
    SELECT 4, N'dbo.products', COUNT_BIG(*)
    FROM dbo.products

    UNION ALL
    SELECT 5, N'dbo.sellers', COUNT_BIG(*)
    FROM dbo.sellers

    UNION ALL
    SELECT 6, N'dbo.category_translation', COUNT_BIG(*)
    FROM dbo.category_translation
) AS counts
ORDER BY display_order;
GO

/* -------------------------------------------------------------------------
   2. Duplicate checks for the business keys

   Each result set should contain zero rows. order_item_id alone is not unique;
   an order item is identified by (order_id, order_item_id).
   ------------------------------------------------------------------------- */
SELECT order_id, COUNT_BIG(*) AS duplicate_count
FROM dbo.orders
GROUP BY order_id
HAVING COUNT_BIG(*) > 1;

SELECT order_id, order_item_id, COUNT_BIG(*) AS duplicate_count
FROM dbo.order_items
GROUP BY order_id, order_item_id
HAVING COUNT_BIG(*) > 1;

SELECT customer_id, COUNT_BIG(*) AS duplicate_count
FROM dbo.customers
GROUP BY customer_id
HAVING COUNT_BIG(*) > 1;

SELECT product_id, COUNT_BIG(*) AS duplicate_count
FROM dbo.products
GROUP BY product_id
HAVING COUNT_BIG(*) > 1;

SELECT seller_id, COUNT_BIG(*) AS duplicate_count
FROM dbo.sellers
GROUP BY seller_id
HAVING COUNT_BIG(*) > 1;

SELECT product_category_name, COUNT_BIG(*) AS duplicate_count
FROM dbo.category_translation
GROUP BY product_category_name
HAVING COUNT_BIG(*) > 1;
GO

/* -------------------------------------------------------------------------
   3. Null checks for important order fields

   Missing approval or delivery timestamps can be valid for orders that have
   not reached those lifecycle stages. They are reported, not treated as fake
   dates or modified.
   ------------------------------------------------------------------------- */
SELECT
    COUNT_BIG(*) AS total_rows,
    COALESCE(SUM(CASE WHEN order_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_order_id,
    COALESCE(SUM(CASE WHEN customer_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_customer_id,
    COALESCE(SUM(CASE WHEN order_status IS NULL OR LTRIM(RTRIM(order_status)) = N''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_order_status,
    COALESCE(SUM(CASE WHEN order_purchase_timestamp IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_purchase_timestamp,
    COALESCE(SUM(CASE WHEN order_approved_at IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_approved_at,
    COALESCE(SUM(CASE WHEN order_delivered_carrier_date IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_delivered_carrier_date,
    COALESCE(SUM(CASE WHEN order_delivered_customer_date IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_delivered_customer_date,
    COALESCE(SUM(CASE WHEN order_estimated_delivery_date IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_estimated_delivery_date
FROM dbo.orders;
GO

/* Important order-item identifiers and measures. */
SELECT
    COUNT_BIG(*) AS total_rows,
    COALESCE(SUM(CASE WHEN order_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_order_id,
    COALESCE(SUM(CASE WHEN order_item_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_order_item_id,
    COALESCE(SUM(CASE WHEN product_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_product_id,
    COALESCE(SUM(CASE WHEN seller_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_seller_id,
    COALESCE(SUM(CASE WHEN shipping_limit_date IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_shipping_limit_date,
    COALESCE(SUM(CASE WHEN price IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_price,
    COALESCE(SUM(CASE WHEN freight_value IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_freight_value
FROM dbo.order_items;
GO

/* Important customer, product, seller, and category fields. */
SELECT
    COUNT_BIG(*) AS total_rows,
    COALESCE(SUM(CASE WHEN customer_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_customer_id,
    COALESCE(SUM(CASE WHEN customer_unique_id IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_customer_unique_id,
    COALESCE(SUM(CASE WHEN customer_zip_code_prefix IS NULL
                           OR LTRIM(RTRIM(customer_zip_code_prefix)) = ''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_customer_zip_code_prefix,
    COALESCE(SUM(CASE WHEN customer_city IS NULL OR LTRIM(RTRIM(customer_city)) = N''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_customer_city,
    COALESCE(SUM(CASE WHEN customer_state IS NULL OR LTRIM(RTRIM(customer_state)) = ''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_customer_state
FROM dbo.customers;

SELECT
    COUNT_BIG(*) AS total_rows,
    COALESCE(SUM(CASE WHEN product_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_product_id,
    COALESCE(SUM(CASE WHEN product_category_name IS NULL
                           OR LTRIM(RTRIM(product_category_name)) = N''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_product_category_name,
    COALESCE(SUM(CASE WHEN product_weight_g IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_product_weight_g,
    COALESCE(SUM(CASE WHEN product_length_cm IS NULL
                           OR product_height_cm IS NULL
                           OR product_width_cm IS NULL
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS rows_missing_one_or_more_dimensions
FROM dbo.products;

SELECT
    COUNT_BIG(*) AS total_rows,
    COALESCE(SUM(CASE WHEN seller_id IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_seller_id,
    COALESCE(SUM(CASE WHEN seller_zip_code_prefix IS NULL
                           OR LTRIM(RTRIM(seller_zip_code_prefix)) = ''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_seller_zip_code_prefix,
    COALESCE(SUM(CASE WHEN seller_city IS NULL OR LTRIM(RTRIM(seller_city)) = N''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_seller_city,
    COALESCE(SUM(CASE WHEN seller_state IS NULL OR LTRIM(RTRIM(seller_state)) = ''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_seller_state
FROM dbo.sellers;

SELECT
    COUNT_BIG(*) AS total_rows,
    COALESCE(SUM(CASE WHEN product_category_name IS NULL
                           OR LTRIM(RTRIM(product_category_name)) = N''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_portuguese_category,
    COALESCE(SUM(CASE WHEN product_category_name_english IS NULL
                           OR LTRIM(RTRIM(product_category_name_english)) = N''
                      THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_or_blank_english_category
FROM dbo.category_translation;
GO

/* -------------------------------------------------------------------------
   4. Order-status distribution
   ------------------------------------------------------------------------- */
SELECT
    order_status,
    COUNT_BIG(*) AS order_count,
    CAST(
        100.0 * COUNT_BIG(*)
        / NULLIF((SELECT COUNT_BIG(*) FROM dbo.orders), 0)
        AS DECIMAL(6,2)
    ) AS percentage_of_orders
FROM dbo.orders
GROUP BY order_status
ORDER BY order_count DESC, order_status;
GO

/* -------------------------------------------------------------------------
   5. Purchase timestamp range
   ------------------------------------------------------------------------- */
SELECT
    MIN(order_purchase_timestamp) AS earliest_purchase_timestamp,
    MAX(order_purchase_timestamp) AS latest_purchase_timestamp
FROM dbo.orders;
GO

/* -------------------------------------------------------------------------
   6. Basic price and freight validation

   Negative-value counts should normally be zero. Zero freight can be valid.
   ------------------------------------------------------------------------- */
SELECT
    COUNT_BIG(*) AS total_order_items,
    COALESCE(SUM(CASE WHEN price IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_price_count,
    COALESCE(SUM(CASE WHEN price < 0 THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS negative_price_count,
    COALESCE(SUM(CASE WHEN price = 0 THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS zero_price_count,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price,
    CAST(AVG(CAST(price AS DECIMAL(18,2))) AS DECIMAL(18,2)) AS average_price,
    CAST(SUM(CAST(price AS DECIMAL(38,2))) AS DECIMAL(38,2)) AS total_price,
    COALESCE(SUM(CASE WHEN freight_value IS NULL THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS null_freight_count,
    COALESCE(SUM(CASE WHEN freight_value < 0 THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS negative_freight_count,
    COALESCE(SUM(CASE WHEN freight_value = 0 THEN CAST(1 AS BIGINT) ELSE 0 END), 0)
        AS zero_freight_count,
    MIN(freight_value) AS minimum_freight,
    MAX(freight_value) AS maximum_freight,
    CAST(AVG(CAST(freight_value AS DECIMAL(18,2))) AS DECIMAL(18,2))
        AS average_freight,
    CAST(SUM(CAST(freight_value AS DECIMAL(38,2))) AS DECIMAL(38,2))
        AS total_freight
FROM dbo.order_items;
GO

/* -------------------------------------------------------------------------
   7. Relationship checks used by the Pig joins

   Missing category translations are reported separately because the Pig job
   intentionally uses a left outer join for that optional lookup.
   ------------------------------------------------------------------------- */
SELECT relationship_name, unmatched_row_count
FROM
(
    SELECT 1 AS display_order,
           N'orders.customer_id -> customers.customer_id' AS relationship_name,
           COUNT_BIG(*) AS unmatched_row_count
    FROM dbo.orders AS o
    LEFT JOIN dbo.customers AS c
        ON o.customer_id = c.customer_id
    WHERE c.customer_id IS NULL

    UNION ALL
    SELECT 2,
           N'order_items.order_id -> orders.order_id',
           COUNT_BIG(*)
    FROM dbo.order_items AS oi
    LEFT JOIN dbo.orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_id IS NULL

    UNION ALL
    SELECT 3,
           N'order_items.product_id -> products.product_id',
           COUNT_BIG(*)
    FROM dbo.order_items AS oi
    LEFT JOIN dbo.products AS p
        ON oi.product_id = p.product_id
    WHERE p.product_id IS NULL

    UNION ALL
    SELECT 4,
           N'order_items.seller_id -> sellers.seller_id',
           COUNT_BIG(*)
    FROM dbo.order_items AS oi
    LEFT JOIN dbo.sellers AS s
        ON oi.seller_id = s.seller_id
    WHERE s.seller_id IS NULL

    UNION ALL
    SELECT 5,
           N'products.category -> category_translation.category',
           COUNT_BIG(*)
    FROM dbo.products AS p
    LEFT JOIN dbo.category_translation AS ct
        ON p.product_category_name = ct.product_category_name
    WHERE p.product_category_name IS NOT NULL
      AND ct.product_category_name IS NULL
) AS relationship_checks
ORDER BY display_order;
GO
