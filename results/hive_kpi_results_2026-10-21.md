# RetailPulse — Verified Hive KPI Output (21 October 2026)

This file records the results of the local manual run of `hive/03_kpi_queries.hql` on Hadoop 2.10.2 and Hive 2.3.9 using the MapReduce execution engine.

```bash
hive --hiveconf hive.cli.print.header=true -f hive/03_kpi_queries.hql
```

All ten queries finished successfully. Scalar results and full tabular outputs are reproduced from the provided terminal log; Hadoop INFO/WARN/progress messages are omitted. Results may differ with other source data or ETL runs.

## KPI 1 — Total Orders

**Result:** 98,199

## KPI 2 — Total Sales Value

**Result:** 15,735,527.03

## KPI 3 — Average Order Value

**Result:** 160.24

## KPI 4 — Total Freight Cost

**Result:** 2,241,126.29

## KPI 5 — Average Delivery Days

**Result:** 12.09 days

## KPI 6 — Late Delivery Rate (%)

**Result:** 8.11%

## KPI 7 — Top 10 Product Categories by Sales

| `product_category` | `order_count` | `item_count` | `total_sales` | `total_freight` |
| --- | --- | --- | --- | --- |
| health_beauty | 8800 | 9634 | 1437665.78 | 181970.65 |
| watches_gifts | 5604 | 5970 | 1298292.47 | 100107.26 |
| bed_bath_table | 9399 | 11097 | 1240386.13 | 204422.07 |
| sports_leisure | 7673 | 8590 | 1147244.63 | 167503.71 |
| computers_accessories | 6654 | 7781 | 1050941.58 | 146619.56 |
| furniture_decor | 6425 | 8298 | 899626.04 | 172160.99 |
| housewares | 5847 | 6915 | 772035.14 | 145209.34 |
| cool_stuff | 3616 | 3779 | 704086.24 | 83315.75 |
| auto | 3872 | 4204 | 678606.64 | 92020.91 |
| garden_tools | 3505 | 4328 | 579525.2 | 98515.26 |

## KPI 8 — Sales by Customer State

| `customer_state` | `order_count` | `total_sales` | `average_order_item_value` |
| --- | --- | --- | --- |
| SP | 41125 | 5878132.06 | 124.66 |
| RJ | 12697 | 2115667.56 | 145.82 |
| MG | 11496 | 1843074.43 | 141.0 |
| RS | 5415 | 877290.59 | 141.25 |
| PR | 4982 | 794196.61 | 138.87 |
| SC | 3599 | 608023.7 | 146.12 |
| BA | 3344 | 606908.66 | 160.35 |
| DF | 2120 | 351327.21 | 146.57 |
| GO | 1998 | 340544.37 | 146.6 |
| ES | 2018 | 323081.03 | 143.72 |
| PE | 1643 | 321018.34 | 178.24 |
| CE | 1323 | 274522.61 | 186.24 |
| PA | 969 | 217480.54 | 201.56 |
| MT | 902 | 186005.11 | 176.48 |
| MA | 736 | 150687.96 | 183.77 |
| PB | 531 | 140523.47 | 234.21 |
| MS | 708 | 135875.69 | 166.11 |
| PI | 490 | 107765.47 | 199.94 |
| RN | 482 | 101895.08 | 192.62 |
| AL | 411 | 96229.4 | 216.73 |
| SE | 345 | 73032.32 | 189.69 |
| TO | 278 | 61103.85 | 194.6 |
| RO | 246 | 57423.77 | 207.31 |
| AM | 147 | 27835.73 | 168.7 |
| AC | 81 | 19669.7 | 213.8 |
| AP | 68 | 16262.8 | 198.33 |
| RR | 45 | 9948.97 | 195.08 |

## KPI 9 — Monthly Sales Trend

| `purchase_year` | `purchase_month` | `order_count` | `total_sales` |
| --- | --- | --- | --- |
| 2016 | 9 | 2 | 279.69 |
| 2016 | 10 | 290 | 51354.52 |
| 2016 | 12 | 1 | 19.62 |
| 2017 | 1 | 787 | 136943.46 |
| 2017 | 2 | 1718 | 283561.69 |
| 2017 | 3 | 2617 | 425617.96 |
| 2017 | 4 | 2377 | 405848.61 |
| 2017 | 5 | 3640 | 582710.83 |
| 2017 | 6 | 3205 | 499652.24 |
| 2017 | 7 | 3946 | 578753.73 |
| 2017 | 8 | 4272 | 661903.52 |
| 2017 | 9 | 4227 | 717102.72 |
| 2017 | 10 | 4547 | 764756.03 |
| 2017 | 11 | 7421 | 1172191.68 |
| 2017 | 12 | 5618 | 861526.77 |
| 2018 | 1 | 7187 | 1101920.01 |
| 2018 | 2 | 6624 | 979486.16 |
| 2018 | 3 | 7168 | 1152656.99 |
| 2018 | 4 | 6919 | 1156248.89 |
| 2018 | 5 | 6833 | 1145686.46 |
| 2018 | 6 | 6145 | 1020381.9 |
| 2018 | 7 | 6233 | 1039783.58 |
| 2018 | 8 | 6421 | 996973.51 |
| 2018 | 9 | 1 | 166.46 |

## KPI 10 — Top 10 Sellers by Sales

| `seller_id` | `seller_city` | `seller_state` | `order_count` | `item_count` | `total_sales` |
| --- | --- | --- | --- | --- | --- |
| 4869f7a5dfa277a7dca6462dcf3b52b2 | guariba | SP | 1131 | 1155 | 249393.44 |
| 7c67e1448b00f6e969d365cea6b010ab | itaquaquecetuba | SP | 982 | 1364 | 239536.44 |
| 53243585a1d6dc2643021fd1853d8905 | lauro de freitas | BA | 358 | 410 | 235856.68 |
| 4a3ca9315b744ce9f8e9374361493884 | ibitinga | SP | 1804 | 1985 | 235359.3 |
| fa1c13f2614d7b5c4749cbc52fecda94 | sumare | SP | 584 | 585 | 202861.67 |
| da8622b14eb17ae2831f4ac5b9dab84a | piracicaba | SP | 1314 | 1551 | 185192.32 |
| 7e93a43ef30c4f03f38b393420bc753a | barueri | SP | 332 | 336 | 178838.42 |
| 1025f0e2d44d7041d6cf58b6550e0bfa | sao paulo | SP | 915 | 1428 | 172860.69 |
| 7a67c85e85bb2ce8582c35f2203ad736 | sao paulo | SP | 1159 | 1170 | 162607.24 |
| 955fee9216a65b617aa5c0531780ce60 | sao paulo | SP | 1286 | 1498 | 160582.9 |

## Interpretation notes

- `total_sales_value` includes freight (`price + freight_value`); it is not net profit or recognized revenue.
- Total orders and average order value use order-level logic; fact rows are order-item-grained.
- Average delivery days and late-delivery rate are calculated for eligible delivered orders with valid comparison values.
- Sales by customer state uses customer location, not seller location.
- Monthly sales are attributed to the purchase month.
- These are point-in-time manual execution results, not a continuously refreshed report.
