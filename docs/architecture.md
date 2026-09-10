# RetailPulse architecture

## End-to-end flow

```text
Olist CSV
    |
    v
SQL Server (RetailPulse)
    |
    v
Sqoop
    |
    v
HDFS Raw Zone
    |
    v
Apache Pig ETL
    |
    v
HDFS Processed Zone
    |
    v
Apache Hive
    |
    v
HiveQL Analytics
```

RetailPulse is a deliberately small batch pipeline. Each component has one clear responsibility, which makes the complete data path suitable for a university presentation and a single-node live demonstration.

## Source system

Six Olist CSV files are loaded manually through DBeaver into the `RetailPulse` SQL Server database. The tables preserve the source column names and act as the structured operational source for the demonstration. SQL validation checks row counts, key quality, important nulls, timestamps, order statuses, price, and freight before ingestion.

## Sqoop ingestion

Sqoop uses the Microsoft SQL Server JDBC driver to import each source table. It writes pipe-delimited text to a matching directory below `/retailpulse/raw`. One mapper is used because the coursework runs on a pseudo-distributed single-node cluster and prioritizes predictable behaviour over ingestion throughput. `--delete-target-dir` makes each full import replace its own prior raw directory.

## HDFS Raw Zone

The raw zone contains table-shaped copies of the SQL Server data:

```text
/retailpulse/raw/orders
/retailpulse/raw/order_items
/retailpulse/raw/customers
/retailpulse/raw/products
/retailpulse/raw/sellers
/retailpulse/raw/category_translation
```

Keeping raw data separate from transformed data makes lineage visible and allows the Pig transformation to be repeated without another database import.

## Pig ETL

Pig loads all six raw datasets with explicit schemas. It removes records that cannot participate safely in the fact dataset, excludes `canceled` and `unavailable` orders, and joins orders, items, customers, products, and sellers. Category translation is a left outer join so a missing English translation does not remove an otherwise valid order item.

The transformation calculates item value and null-safe delivery measures. Its output grain is one product item in one customer order.

## HDFS Processed Zone

The single processed dataset is stored as pipe-delimited text at:

```text
/retailpulse/processed/order_item_enriched
```

The Pig job replaces this path when rerun. No additional zones are introduced because they would not add value to the MVP.

## Hive analytical layer

Hive database `retailpulse` contains an external table named `fact_order_item` over the processed HDFS path. The external table references the existing files rather than copying them. Three compact marts summarize category sales, state sales, and monthly delivery performance. Separate HiveQL queries answer the ten coursework KPIs.

Order-level metrics first reduce the item-grain fact to one row per order. This prevents orders with several items from being counted several times in average order value and delivery calculations.

## MapReduce and YARN

MapReduce is the batch execution engine used by this Hadoop 2.10.2 coursework environment. Pig joins and aggregations, and Hive queries configured for the MapReduce engine, are translated into one or more MapReduce jobs.

YARN manages the cluster resources used by those jobs. Its ResourceManager coordinates work while the NodeManager launches and monitors containers on the single machine. HDFS stores the input and output; YARN schedules computation; MapReduce performs the batch processing.

## Rerun model

This MVP uses full refreshes:

- Sqoop replaces each table's raw target directory.
- Pig removes and recreates the processed output directory.
- Hive keeps the external fact definition and rebuilds the three small managed marts.

The approach is easy to explain and reproduce, but it is not an incremental or production-grade ingestion design.

