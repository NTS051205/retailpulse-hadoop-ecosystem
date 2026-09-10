-- RetailPulse HiveQL analytics
-- Run 01_create_external_tables.hql and 02_create_marts.hql first.
--
-- fact_order_item has one row per order item. Queries for order-level KPIs
-- explicitly deduplicate by order_id before calculating their final measure.

USE retailpulse;

SET hive.execution.engine=mr;

-- -------------------------------------------------------------------------
-- KPI 1: Total Orders
-- -------------------------------------------------------------------------
SELECT
    COUNT(DISTINCT order_id) AS total_orders
FROM fact_order_item;

-- -------------------------------------------------------------------------
-- KPI 2: Total Sales Value
-- Sales value includes price plus freight, as defined by item_total_value.
-- -------------------------------------------------------------------------
SELECT
    ROUND(SUM(item_total_value), 2) AS total_sales_value
FROM fact_order_item;

-- -------------------------------------------------------------------------
-- KPI 3: Average Order Value
-- First sum all items belonging to each order, then average those order totals.
-- -------------------------------------------------------------------------
SELECT
    ROUND(AVG(order_totals.order_value), 2) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(item_total_value) AS order_value
    FROM fact_order_item
    GROUP BY order_id
) order_totals;

-- -------------------------------------------------------------------------
-- KPI 4: Total Freight Cost
-- -------------------------------------------------------------------------
SELECT
    ROUND(SUM(freight_value), 2) AS total_freight_cost
FROM fact_order_item;

-- -------------------------------------------------------------------------
-- KPI 5: Average Delivery Days
-- Delivery duration is an order attribute repeated across item rows, so the
-- inner query retains one value per delivered order before taking the average.
-- -------------------------------------------------------------------------
SELECT
    ROUND(AVG(delivered_orders.delivery_days), 2) AS average_delivery_days
FROM (
    SELECT
        order_id,
        MAX(delivery_days) AS delivery_days
    FROM fact_order_item
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND delivery_days IS NOT NULL
    GROUP BY order_id
) delivered_orders;

-- -------------------------------------------------------------------------
-- KPI 6: Late Delivery Rate
-- The percentage uses only delivered orders with a computable is_late value;
-- missing actual or estimated dates therefore never become false on-time rows.
-- -------------------------------------------------------------------------
SELECT
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
    END AS late_delivery_rate_percent
FROM (
    SELECT
        order_id,
        MAX(is_late) AS is_late
    FROM fact_order_item
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
    GROUP BY order_id
) delivered_orders;

-- -------------------------------------------------------------------------
-- KPI 7: Top 10 Product Categories by Sales
-- -------------------------------------------------------------------------
SELECT
    product_category,
    order_count,
    item_count,
    total_sales,
    total_freight
FROM mart_sales_category
ORDER BY total_sales DESC
LIMIT 10;

-- -------------------------------------------------------------------------
-- KPI 8: Sales by Customer State
-- -------------------------------------------------------------------------
SELECT
    customer_state,
    order_count,
    total_sales,
    average_order_item_value
FROM mart_sales_state
ORDER BY total_sales DESC;

-- -------------------------------------------------------------------------
-- KPI 9: Monthly Sales Trend
-- -------------------------------------------------------------------------
SELECT
    YEAR(order_purchase_timestamp)              AS purchase_year,
    MONTH(order_purchase_timestamp)             AS purchase_month,
    COUNT(DISTINCT order_id)                    AS order_count,
    ROUND(SUM(item_total_value), 2)             AS total_sales
FROM fact_order_item
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY
    purchase_year,
    purchase_month;

-- -------------------------------------------------------------------------
-- KPI 10: Top 10 Sellers by Sales
-- -------------------------------------------------------------------------
SELECT
    seller_id,
    MAX(seller_city)                            AS seller_city,
    MAX(seller_state)                           AS seller_state,
    COUNT(DISTINCT order_id)                    AS order_count,
    COUNT(*)                                    AS item_count,
    ROUND(SUM(item_total_value), 2)             AS total_sales
FROM fact_order_item
GROUP BY seller_id
ORDER BY total_sales DESC
LIMIT 10;
