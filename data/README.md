# Dataset placement

RetailPulse uses the public **Olist Brazilian E-Commerce** dataset. Download it manually from the dataset provider; the project does not download or redistribute it.

Only these six source files are in scope:

1. `olist_orders_dataset.csv`
2. `olist_order_items_dataset.csv`
3. `olist_customers_dataset.csv`
4. `olist_products_dataset.csv`
5. `olist_sellers_dataset.csv`
6. `product_category_name_translation.csv`

You may keep the files anywhere accessible to DBeaver. If you want them beside the project while working locally, place them directly under `data/`. The repository-wide `*.csv` rule in `.gitignore` prevents CSV files from being committed.

## Manual loading responsibility

The CSV files are loaded manually into the six SQL Server tables created by `sql/01_create_database_and_tables.sql`. Run that DDL with DBeaver's **Execute SQL Script** action so its `GO` batch separators are recognized. Then use CSV import with:

- the first row treated as column names;
- comma as the field delimiter;
- double quote (`"`) as the quote character;
- UTF-8 encoding;
- empty source values mapped to SQL `NULL` where the target column is nullable;
- source columns mapped by their exact Olist names, including `product_name_lenght` and `product_description_lenght`.
- both postal-code prefix columns mapped as text to their `VARCHAR(5)` targets so source leading zeros are preserved.
- for a reliable SQL Server import, **Disable batches** set to **Yes** and **Use multi-row insert** set to **No** in DBeaver's data-load settings.

Do not load payment, review, geolocation, or any other Olist files for this MVP. After loading all six tables, run `sql/02_source_validation.sql` in DBeaver before starting Sqoop.
