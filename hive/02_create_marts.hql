-- RetailPulse aggregate marts
-- Run hive/01_create_external_tables.hql before this script.
--
-- fact_order_item is at order-item grain. DISTINCT order IDs or an explicit
-- one-row-per-order subquery are therefore used for order-level measures.

USE retailpulse;

SET hive.execution.engine=mr;

-- -------------------------------------------------------------------------
-- Sales by product category
-- total_sales includes item price plus freight because item_total_value is
-- defined by the Pig transformation as price + freight_value.
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS mart_sales_category;

CREATE TABLE mart_sales_category
STORED AS ORC
AS
SELECT
    COALESCE(product_category_english,
             product_category_name,
             'unknown')                         AS product_category,
    COUNT(DISTINCT order_id)                    AS order_count,
    COUNT(*)                                    AS item_count,
    ROUND(SUM(item_total_value), 2)             AS total_sales,
    ROUND(SUM(freight_value), 2)                AS total_freight
FROM fact_order_item
GROUP BY
    COALESCE(product_category_english,
             product_category_name,
             'unknown');

-- -------------------------------------------------------------------------
-- Sales by customer state
-- average_order_item_value is intentionally an item-grain average, while
-- order_count is distinct because one order can contain multiple items.
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS mart_sales_state;

CREATE TABLE mart_sales_state
STORED AS ORC
AS
SELECT
    customer_state                              AS customer_state,
    COUNT(DISTINCT order_id)                    AS order_count,
    ROUND(SUM(item_total_value), 2)             AS total_sales,
    ROUND(AVG(item_total_value), 2)             AS average_order_item_value
FROM fact_order_item
GROUP BY customer_state;

-- -------------------------------------------------------------------------
-- Monthly delivery performance
-- The inner query collapses repeated item rows to one row per delivered order.
-- COUNT(is_late) is the number of delivered orders whose actual and estimated
-- dates were both valid. It is used as the late-rate denominator so an unknown
-- delivery status is not silently treated as an on-time delivery.
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS mart_delivery_monthly;

CREATE TABLE mart_delivery_monthly
STORED AS ORC
AS
SELECT
    delivered_orders.purchase_year             AS purchase_year,
    delivered_orders.purchase_month            AS purchase_month,
    COUNT(*)                                    AS delivered_order_count,
    ROUND(AVG(delivered_orders.delivery_days), 2)
                                                AS average_delivery_days,
    SUM(CASE
            WHEN delivered_orders.is_late = 1 THEN 1
            ELSE 0
        END)                                    AS late_delivery_count,
    CASE
        WHEN COUNT(delivered_orders.is_late) = 0 THEN CAST(NULL AS DOUBLE)
        ELSE ROUND(
            100.0 * SUM(CASE
                            WHEN delivered_orders.is_late = 1 THEN 1
                            ELSE 0
                        END)
            / COUNT(delivered_orders.is_late),
            2
        )
    END                                         AS late_delivery_rate
FROM (
    SELECT
        order_id                                AS order_id,
        YEAR(order_purchase_timestamp)          AS purchase_year,
        MONTH(order_purchase_timestamp)         AS purchase_month,
        MAX(delivery_days)                      AS delivery_days,
        MAX(is_late)                            AS is_late
    FROM fact_order_item
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp IS NOT NULL
      AND order_delivered_customer_date IS NOT NULL
    GROUP BY
        order_id,
        YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp)
) delivered_orders
GROUP BY
    delivered_orders.purchase_year,
    delivered_orders.purchase_month;
