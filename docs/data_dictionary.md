# RetailPulse Data Dictionary

This document describes the six SQL Server source tables and the final enriched
dataset exposed to Hive as `retailpulse.fact_order_item`.

## Data-grain summary

- `dbo.orders`: one row per customer order.
- `dbo.order_items`: one row per numbered product item within an order.
- `dbo.customers`: one row per order-level customer identifier.
- `dbo.products`: one row per product.
- `dbo.sellers`: one row per seller.
- `dbo.category_translation`: one row per Portuguese product-category name.
- `fact_order_item`: **One row represents one product item in one customer
  order.** Its business key is `(order_id, order_item_id)`.

Olist's original column names are retained in the source schema. In particular,
`product_name_lenght` and `product_description_lenght` are intentionally not
corrected because `lenght` is how those fields are named in the source CSV.

## A. SQL Server source tables

### `dbo.orders`

Source file: `olist_orders_dataset.csv`

| Field | SQL Server type | Nullable | Description |
|---|---|---:|---|
| `order_id` | `CHAR(32)` | No | Olist order identifier; primary key. |
| `customer_id` | `CHAR(32)` | No | Order-level customer identifier used to join to `dbo.customers`. |
| `order_status` | `NVARCHAR(30)` | No | Order lifecycle status, such as `delivered`, `shipped`, `canceled`, or `unavailable`. |
| `order_purchase_timestamp` | `DATETIME2(0)` | No | Date and time when the customer placed the order. |
| `order_approved_at` | `DATETIME2(0)` | Yes | Date and time when the order was approved; absent for some order states. |
| `order_delivered_carrier_date` | `DATETIME2(0)` | Yes | Date and time when the order was handed to the carrier. |
| `order_delivered_customer_date` | `DATETIME2(0)` | Yes | Actual customer delivery date and time; absent when no delivery was recorded. |
| `order_estimated_delivery_date` | `DATETIME2(0)` | No | Delivery date and time estimated for the order. |

### `dbo.order_items`

Source file: `olist_order_items_dataset.csv`

| Field | SQL Server type | Nullable | Description |
|---|---|---:|---|
| `order_id` | `CHAR(32)` | No | Order identifier; joins to `dbo.orders`. |
| `order_item_id` | `INT` | No | Item sequence number within an order. Together with `order_id`, this forms the primary key. |
| `product_id` | `CHAR(32)` | No | Product identifier; joins to `dbo.products`. |
| `seller_id` | `CHAR(32)` | No | Seller identifier; joins to `dbo.sellers`. |
| `shipping_limit_date` | `DATETIME2(0)` | No | Seller's shipping deadline for the item. |
| `price` | `DECIMAL(12,2)` | No | Product selling price, excluding freight. |
| `freight_value` | `DECIMAL(12,2)` | No | Freight amount charged for this item. |

### `dbo.customers`

Source file: `olist_customers_dataset.csv`

| Field | SQL Server type | Nullable | Description |
|---|---|---:|---|
| `customer_id` | `CHAR(32)` | No | Order-level customer identifier; primary key. |
| `customer_unique_id` | `CHAR(32)` | No | Stable identifier that can link orders from the same customer. It is not unique in this table because a customer can place multiple orders. |
| `customer_zip_code_prefix` | `VARCHAR(5)` | No | Prefix of the customer's Brazilian postal code, stored as text so a source leading zero is not lost. |
| `customer_city` | `NVARCHAR(100)` | No | Customer city recorded by Olist. |
| `customer_state` | `CHAR(2)` | No | Two-letter Brazilian state code used in state-level analytics. |

### `dbo.products`

Source file: `olist_products_dataset.csv`

| Field | SQL Server type | Nullable | Description |
|---|---|---:|---|
| `product_id` | `CHAR(32)` | No | Product identifier; primary key. |
| `product_category_name` | `NVARCHAR(100)` | Yes | Portuguese product-category name; joins to `dbo.category_translation`. |
| `product_name_lenght` | `INT` | Yes | Number of characters in the product name. The source misspelling is preserved. |
| `product_description_lenght` | `INT` | Yes | Number of characters in the product description. The source misspelling is preserved. |
| `product_photos_qty` | `INT` | Yes | Number of product photos. |
| `product_weight_g` | `DECIMAL(10,2)` | Yes | Product weight in grams. |
| `product_length_cm` | `DECIMAL(10,2)` | Yes | Product length in centimetres. |
| `product_height_cm` | `DECIMAL(10,2)` | Yes | Product height in centimetres. |
| `product_width_cm` | `DECIMAL(10,2)` | Yes | Product width in centimetres. |

### `dbo.sellers`

Source file: `olist_sellers_dataset.csv`

| Field | SQL Server type | Nullable | Description |
|---|---|---:|---|
| `seller_id` | `CHAR(32)` | No | Seller identifier; primary key. |
| `seller_zip_code_prefix` | `VARCHAR(5)` | No | Prefix of the seller's Brazilian postal code, stored as text so a source leading zero is not lost. |
| `seller_city` | `NVARCHAR(100)` | No | Seller city recorded by Olist. |
| `seller_state` | `CHAR(2)` | No | Two-letter Brazilian state code. |

### `dbo.category_translation`

Source file: `product_category_name_translation.csv`

| Field | SQL Server type | Nullable | Description |
|---|---|---:|---|
| `product_category_name` | `NVARCHAR(100)` | No | Portuguese category name; primary key and lookup key from `dbo.products`. |
| `product_category_name_english` | `NVARCHAR(100)` | No | English translation of the product-category name. |

### Source-schema conventions

- Olist identifiers are fixed 32-character values and are stored as `CHAR(32)`.
- Timestamps use `DATETIME2(0)` because the source format is
  `yyyy-MM-dd HH:mm:ss` and contains second-level precision.
- Source money values use fixed-precision `DECIMAL` types. Pig and Hive use
  `DOUBLE` for the coursework aggregations, so minor floating-point display
  differences are possible when compared with SQL Server totals.
- Postal-code prefixes use `VARCHAR(5)` because they are identifiers rather
  than quantities; textual storage preserves any leading zero present in CSV.
- Product attributes are nullable because the Olist product file contains
  missing descriptive and physical measurements.
- No foreign-key constraints are added. The read-only validation script reports
  unmatched relationships before the inner joins performed by Pig.

## B. Final `fact_order_item` dataset

HDFS location: `/retailpulse/processed/order_item_enriched`

Hive table: `retailpulse.fact_order_item`

Field delimiter: `|`

The table columns must remain in the following order because the Hive external
table reads positional text output produced by Pig.

| Position | Field | Pig type | Hive type | Nullable | Source or derivation |
|---:|---|---|---|---:|---|
| 1 | `order_id` | `chararray` | `STRING` | No | `orders.order_id`, joined to `order_items.order_id`. |
| 2 | `order_item_id` | `int` | `INT` | No | `order_items.order_item_id`; item sequence within the order. |
| 3 | `customer_id` | `chararray` | `STRING` | No | `orders.customer_id`, joined to `customers.customer_id`. |
| 4 | `customer_unique_id` | `chararray` | `STRING` | No | `customers.customer_unique_id`. |
| 5 | `customer_city` | `chararray` | `STRING` | No | `customers.customer_city`. |
| 6 | `customer_state` | `chararray` | `STRING` | No | `customers.customer_state`; grouping dimension for state analytics. |
| 7 | `product_id` | `chararray` | `STRING` | No | `order_items.product_id`, joined to `products.product_id`. |
| 8 | `product_category_name` | `chararray` | `STRING` | Yes | Portuguese category from `products.product_category_name`. It can be absent in the source. |
| 9 | `product_category_english` | `chararray` | `STRING` | Yes | `category_translation.product_category_name_english`, obtained with a left outer join so an item is retained when no translation exists. |
| 10 | `seller_id` | `chararray` | `STRING` | No | `order_items.seller_id`, joined to `sellers.seller_id`. |
| 11 | `seller_city` | `chararray` | `STRING` | No | `sellers.seller_city`. |
| 12 | `seller_state` | `chararray` | `STRING` | No | `sellers.seller_state`. |
| 13 | `order_status` | `chararray` | `STRING` | No | `orders.order_status`; rows with `canceled` or `unavailable` are excluded by Pig. |
| 14 | `order_purchase_timestamp` | `chararray` | `TIMESTAMP` | No | Parsed from `orders.order_purchase_timestamp`, then written in normalized `yyyy-MM-dd HH:mm:ss` form for Hive. |
| 15 | `order_delivered_customer_date` | `chararray` | `TIMESTAMP` | Yes | Parsed from `orders.order_delivered_customer_date`; remains null when the source date is missing or invalid. |
| 16 | `order_estimated_delivery_date` | `chararray` | `TIMESTAMP` | Yes | Parsed from `orders.order_estimated_delivery_date`; remains null if it cannot be parsed. |
| 17 | `price` | `double` | `DOUBLE` | No | Numeric form of `order_items.price`; product price excluding freight. |
| 18 | `freight_value` | `double` | `DOUBLE` | No | Numeric form of `order_items.freight_value`. |
| 19 | `item_total_value` | `double` | `DOUBLE` | No | `price + freight_value` for one order item. |
| 20 | `delivery_days` | `long` | `BIGINT` | Yes | Whole-day difference between actual customer delivery and purchase time. Null when either timestamp is unavailable. |
| 21 | `delay_days` | `long` | `BIGINT` | Yes | Whole elapsed-day difference `actual delivery - estimated delivery`. Positive means at least one whole day late, negative means early, and zero means the timestamps differ by less than one whole day. Null when either timestamp is unavailable. |
| 22 | `is_late` | `int` | `INT` | Yes | Direct timestamp comparison: `1` when valid actual delivery is after the valid estimate, `0` when it is on or before the estimate, and null when the comparison cannot be made. |

### Fact-table metric notes

- `price`, `freight_value`, and `item_total_value` are additive at the order-item
  grain.
- `COUNT(DISTINCT order_id)` is required for order counts because one order can
  contain several item rows.
- Order value must first be summed by `order_id`; average order value is the
  average of those order-level totals, not the average item value.
- Delivery fields repeat across all items in the same order. Delivery averages,
  delivered-order counts, late-order counts, and late-delivery rates must first
  reduce the fact data to one row per `order_id` to avoid weighting multi-item
  orders more heavily.
- `late_delivery_rate` is reported as a percentage from 0 to 100. Its
  denominator is delivered orders for which `is_late` can be computed from
  valid actual and estimated delivery timestamps.
- An undelivered order has null delivery metrics and a null `is_late`; it must
  not be counted as an on-time delivery.
