/*
    RetailPulse source database and tables
    Target platform: Microsoft SQL Server 2022

    The six tables below mirror the selected Olist CSV files. CSV loading is
    intentionally not included; import each file manually with DBeaver after
    running this script.

    This script is rerunnable: it creates the database and each table only when
    they do not already exist. It never drops or truncates existing data.
*/

USE [master];
GO

IF DB_ID(N'RetailPulse') IS NULL
BEGIN
    -- CREATE DATABASE must run in its own batch, so dynamic SQL is used here.
    EXEC (N'CREATE DATABASE [RetailPulse];');
END;
GO

USE [RetailPulse];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Source file: olist_orders_dataset.csv */
IF OBJECT_ID(N'dbo.orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.orders
    (
        order_id                       CHAR(32)      NOT NULL,
        customer_id                    CHAR(32)      NOT NULL,
        order_status                   NVARCHAR(30)  NOT NULL,
        order_purchase_timestamp       DATETIME2(0)  NOT NULL,
        order_approved_at               DATETIME2(0)  NULL,
        order_delivered_carrier_date   DATETIME2(0)  NULL,
        order_delivered_customer_date  DATETIME2(0)  NULL,
        order_estimated_delivery_date  DATETIME2(0)  NOT NULL,

        CONSTRAINT PK_orders PRIMARY KEY (order_id)
    );
END;
GO

/* Source file: olist_order_items_dataset.csv */
IF OBJECT_ID(N'dbo.order_items', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.order_items
    (
        order_id             CHAR(32)      NOT NULL,
        order_item_id        INT           NOT NULL,
        product_id           CHAR(32)      NOT NULL,
        seller_id            CHAR(32)      NOT NULL,
        shipping_limit_date  DATETIME2(0)  NOT NULL,
        price                DECIMAL(12,2) NOT NULL,
        freight_value        DECIMAL(12,2) NOT NULL,

        -- order_item_id restarts within each order, so the key is composite.
        CONSTRAINT PK_order_items PRIMARY KEY (order_id, order_item_id)
    );
END;
GO

/* Source file: olist_customers_dataset.csv */
IF OBJECT_ID(N'dbo.customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.customers
    (
        customer_id               CHAR(32)       NOT NULL,
        customer_unique_id        CHAR(32)       NOT NULL,
        customer_zip_code_prefix  VARCHAR(5)     NOT NULL,
        customer_city             NVARCHAR(100)  NOT NULL,
        customer_state            CHAR(2)        NOT NULL,

        -- customer_unique_id is not unique: one person can have multiple orders.
        CONSTRAINT PK_customers PRIMARY KEY (customer_id)
    );
END;
GO

/* Source file: olist_products_dataset.csv */
IF OBJECT_ID(N'dbo.products', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.products
    (
        product_id                  CHAR(32)       NOT NULL,
        product_category_name       NVARCHAR(100)  NULL,
        product_name_lenght          INT            NULL,
        product_description_lenght   INT            NULL,
        product_photos_qty           INT            NULL,
        product_weight_g             DECIMAL(10,2)  NULL,
        product_length_cm            DECIMAL(10,2)  NULL,
        product_height_cm            DECIMAL(10,2)  NULL,
        product_width_cm             DECIMAL(10,2)  NULL,

        -- "lenght" is deliberately preserved from the original Olist headers.
        CONSTRAINT PK_products PRIMARY KEY (product_id)
    );
END;
GO

/* Source file: olist_sellers_dataset.csv */
IF OBJECT_ID(N'dbo.sellers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sellers
    (
        seller_id               CHAR(32)       NOT NULL,
        seller_zip_code_prefix  VARCHAR(5)     NOT NULL,
        seller_city             NVARCHAR(100)  NOT NULL,
        seller_state            CHAR(2)        NOT NULL,

        CONSTRAINT PK_sellers PRIMARY KEY (seller_id)
    );
END;
GO

/* Source file: product_category_name_translation.csv */
IF OBJECT_ID(N'dbo.category_translation', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.category_translation
    (
        product_category_name          NVARCHAR(100)  NOT NULL,
        product_category_name_english  NVARCHAR(100)  NOT NULL,

        CONSTRAINT PK_category_translation
            PRIMARY KEY (product_category_name)
    );
END;
GO
