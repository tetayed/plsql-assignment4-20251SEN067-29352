# Supermarket Order and Inventory Management System

## 1. Project overview

This project is an educational Oracle Database and PL/SQL exercise. It models a small supermarket catalog, customers, orders, and order items. Its routines demonstrate how procedural code can read and modify relational data, apply a discount rule, handle errors, and update several related tables.

The project is intended to teach database programming concepts. It is not a complete retail application or a production-ready inventory system.

## 2. Project structure

| Path | Role |
|---|---|
| `00_Schema/01_create_tables.sql` | Drops and recreates the four tables and their constraints. |
| `00_Schema/02_insert_sample_data.sql` | Inserts example customers, products, an order, and its items, then commits the sample data. |
| `01_Procedures/sq_process_order.sql` | Creates `sp_process_order`, which processes a one-product order. The filename begins with `sq_`, but the procedure itself is named `sp_process_order`. |
| `01_Procedures/sp_bulk_restock.sql` | Creates `sp_bulk_restock`, which adds stock to products at or below a threshold using bulk PL/SQL operations. |
| `02_Functions/fn_calculate_discount.sql` | Creates `fn_calculate_discount`, which returns a discount amount based on customer loyalty points. |
| `02_Functions/fn_check_stock.sql` | Creates `fn_check_stock`, which reports whether a product has enough stock for a requested quantity. |
| `03_tests/test_success_cases.sql` | Manually demonstrates discount calculation, order processing, and bulk restocking. |
| `03_tests/test_error_cases.sql` | Manually demonstrates insufficient-stock, missing-customer, and invalid-subtotal errors. |
| `Screenshots/` | Stores screenshots documenting selected execution or compilation results. |

## 3. Database design

The schema has four tables. The foreign keys define the main relationships:

- One customer can have many orders.
- One order can have many order items.
- One product can appear in many order items.
- Each order item refers to one order and one product.

### `customers`

Stores customer identity and loyalty information.

| Column | Role |
|---|---|
| `customer_id` | Primary key identifying a customer. |
| `customer_name` | Required customer display name. |
| `email` | Required email address; the unique constraint prevents duplicate email values. |
| `loyalty_points` | Points used to determine the discount tier. Defaults to zero when omitted. |
| `created_at` | Customer creation date. Defaults to the database's current date and time (`SYSDATE`). |

### `products`

Stores product descriptions, prices, and current inventory.

| Column | Role |
|---|---|
| `product_id` | Primary key identifying a product. |
| `product_name` | Required product name. |
| `unit_price` | Required price per unit. `chk_price_positive` requires the value to be greater than zero. |
| `stock_quantity` | Required current stock count. `chk_stock_positive` prevents negative stock. |

### `orders`

Stores the order header: the customer, date, total, and status.

| Column | Role |
|---|---|
| `order_id` | Primary key identifying an order. |
| `customer_id` | Required reference to the customer who placed the order. |
| `order_date` | Required order timestamp; defaults to `SYSDATE`. |
| `total_amount` | Order total. Defaults to zero when omitted. |
| `ord_status` | Required status, defaulting to `PENDING`. `chk_order_status` permits `PENDING`, `COMPLETED`, or `CANCELLED`. |

`sp_process_order` explicitly inserts new orders with status `COMPLETED`; it does not use the default `PENDING` status.

### `order_items`

Stores the product and quantity for each order line.

| Column | Role |
|---|---|
| `item_id` | Primary key identifying an order line. |
| `order_id` | Required reference to the order. `ON DELETE CASCADE` means deleting the order also deletes its item rows. |
| `product_id` | Required reference to the product. |
| `quantity` | Required ordered quantity. `chk_qty_positive` requires a value greater than zero. |
| `unit_price` | Price recorded for this item when the order is inserted. This acts as a price snapshot for the line. |

The `quantity` column is declared as `NUMBER(4)` (scale zero), but the procedure parameter is an unconstrained `NUMBER` and does not explicitly reject fractional input. Oracle can round the value stored in the item row while the inventory update uses the original parameter value. The schema also does not ensure that `total_amount` matches the sum of the order items.

## 4. PL/SQL functions and procedures

### `fn_calculate_discount`

**File:** `02_Functions/fn_calculate_discount.sql`

**Purpose:** Returns a numeric discount amount for a customer and a positive subtotal.

**Parameters**

- `p_customer_id`: identifies the customer whose loyalty points determine the discount.
- `p_subtotal`: amount on which the discount is calculated; must be greater than zero.

**Discount tiers**

| Loyalty points | Discount |
|---:|---:|
| 150 or more | 15% |
| 50–149 | 5% |
| Less than 50 | 0% |

**How it works**

1. Rejects a subtotal less than or equal to zero with application error `-20002`.
2. Opens the explicit cursor `c_customer`, fetches the customer's ID and loyalty points into the user-defined `customer_discount_rec` record, and closes the cursor.
3. Raises application error `-20001` if the customer does not exist.
4. Selects a discount rate from the tiers and returns `p_subtotal * discount_rate`.
5. In the exception handler, closes the cursor if an error occurred while it was open, then re-raises the error.

The record groups the fetched customer ID, points, and selected discount rate. The cursor demonstrates explicit cursor lifecycle operations (`OPEN`, `FETCH`, and `CLOSE`).

### `fn_check_stock`

**File:** `02_Functions/fn_check_stock.sql`

**Purpose:** Returns `TRUE` when a product's current stock is at least the requested quantity; otherwise returns `FALSE`.

**Parameters**

- `p_product_id`: product to check.
- `p_req_qty`: requested quantity.

The function selects `stock_quantity` into a local variable and compares it with `p_req_qty`. If the product ID does not exist, it raises application error `-20003`.

This function is a separate demonstration helper; `sp_process_order` currently performs its own stock check and does not call `fn_check_stock`. The function returns PL/SQL `BOOLEAN`, which is intended for use from PL/SQL blocks rather than directly as a SQL query result in Oracle versions without SQL Boolean support.

### `sp_process_order`

**File:** `01_Procedures/sq_process_order.sql`

**Purpose:** Creates one order containing one product line, calculates its discount, and deducts the ordered quantity from inventory.

**Parameters**

- `p_customer_id`: customer placing the order.
- `p_product_id`: product being ordered.
- `p_quantity`: quantity to order.

**How it works**

1. Reads the product row into `v_product_rec`, declared as `products%ROWTYPE`. If the product does not exist, the query raises `NO_DATA_FOUND`.
2. Checks that available stock is not less than the requested quantity. If stock is insufficient, it raises the local exception `e_insufficient_stock`.
3. Calculates the item subtotal from the product price and quantity.
4. Calls `fn_calculate_discount` and subtracts the returned discount to get `v_final_total`.
5. Generates an order ID and item ID using `MAX(id) + 1`, with starting fallback values of 500 and 1000 respectively.
6. Inserts a completed order and its order item.
7. Deducts the requested quantity from the product's stock.
8. Uses the implicit cursor attribute `SQL%FOUND` after the inventory update and prints a success message if the update affected a row.
9. Commits on success. A `NO_DATA_FOUND` error is translated to application error `-20005`; insufficient stock is translated to `-20006`. Other errors trigger a rollback and are re-raised.

The numeric variables hold IDs, item subtotal, discount, and final total. The local exception provides a named path for the insufficient-stock case.

This procedure supports only one product per order call. It also owns its `COMMIT`, so invoking it commits the caller's current transaction as well.

### `sp_bulk_restock`

**File:** `01_Procedures/sp_bulk_restock.sql`

**Purpose:** Adds a fixed quantity to every product whose stock is at or below a supplied threshold.

**Parameters**

- `p_threshold`: products with `stock_quantity <= p_threshold` are selected.
- `p_add_qty`: amount added to each selected product's stock.

**How it works**

1. `BULK COLLECT` loads matching product IDs into the nested-table collection `v_low_stock_ids`. The collection element type uses `products.product_id%TYPE` so it follows the column's data type.
2. If the collection is empty, the procedure prints a message and returns without updating any products.
3. `FORALL` submits the updates in bulk. `SAVE EXCEPTIONS` allows Oracle to attempt all collection entries and collect row-level errors.
4. It prints `SQL%ROWCOUNT`, the number of rows affected by the most recent DML statement, on successful completion.
5. The exception mapped to Oracle error `-24381` prints the count and details of bulk errors in `SQL%BULK_EXCEPTIONS`. Other errors are translated to application error `-20004`.

The procedure does not issue a `COMMIT`; its updates remain part of the caller's transaction until that caller commits or rolls back. The current implementation also does not validate that the threshold or added quantity is positive.

## 5. Sample data

`02_insert_sample_data.sql` populates:

- Five customers with different loyalty-point balances, covering the discount tiers.
- Ten products, including low-stock products for the restock demonstration.
- One completed sample order and two order items.

The explicit IDs in the sample data make the examples easy to read. The script commits these inserts at the end.

## 6. Test scripts

These are SQL*Plus/SQLcl-style manual demonstrations, not an automated unit-test suite.

### Success demonstrations

`test_success_cases.sql`:

1. Calls `fn_calculate_discount` for customer 1 with a subtotal of 10,000. Customer 1 has 120 points, so the expected discount amount is 500.
2. Orders two units of product 101 for customer 1. With the provided sample data, the item subtotal is 2,400, the discount is 120, and the final total is 2,280. The stock should decrease from 50 to 48.
3. Calls `sp_bulk_restock` with threshold 10 and add quantity 50. With the sample data and before other changes, products 102, 104, and 106 meet the threshold; product 101 is also included if its stock has been reduced to 10 or less.
4. Runs queries to display the latest order, its items, the stock for product 101, and selected low-stock products.

The order procedure commits, so running the success script repeatedly changes the database. The displayed values are not automatically asserted by the script.

### Error demonstrations

`test_error_cases.sql` demonstrates:

1. An order for far more units than product 103 has in stock, expected to raise `-20006`.
2. An order for a non-existent customer. The order routine calls `fn_calculate_discount`, which raises `-20001` for the missing customer.
3. A negative subtotal passed directly to `fn_calculate_discount`, expected to raise `-20002`.

Each test catches `WHEN OTHERS` and prints the error. This is useful for observing errors during a lesson, but it does not verify that the specific expected error occurred.

## 7. Suggested execution order

Run the scripts in an Oracle environment, such as SQL Developer or SQLcl, in this order:

1. `00_Schema/01_create_tables.sql`
2. `00_Schema/02_insert_sample_data.sql`
3. `02_Functions/fn_calculate_discount.sql`
4. `02_Functions/fn_check_stock.sql`
5. `01_Procedures/sp_bulk_restock.sql`
6. `01_Procedures/sq_process_order.sql`
7. `03_tests/test_success_cases.sql`
8. `03_tests/test_error_cases.sql`

The discount function must be compiled before `sp_process_order`, because the procedure calls it. The stock-check function is independent and is not currently called by either procedure.

The `/` lines at the end of stored PL/SQL definitions and anonymous blocks are client commands that tell SQL*Plus/SQLcl to execute the buffered statement. `SET SERVEROUTPUT ON` enables display of `DBMS_OUTPUT.PUT_LINE` messages in those clients.

## 8. Educational scope and practical limitations

This project focuses on core relational and PL/SQL concepts. The following are intentional simplifications or areas for future learning; they are not implemented features:

- IDs are generated with `MAX(id) + 1`, which is not safe for concurrent sessions. Oracle sequences or identity columns are more appropriate for concurrent applications.
- The order procedure commits internally, limiting transaction control by the calling application.
- The stock check and subsequent stock update are separate operations; concurrent orders require stronger coordination to avoid race conditions and clearer handling of stock conflicts.
- Bulk-restock inputs are not validated, and bulk row errors are printed rather than re-raised to the caller.
- Tests display output rather than asserting expected database state or exact error codes.
- The schema does not model suppliers, restock history, payments, shipping, authentication/authorization, or a full cancellation/refund workflow.
- Order processing supports only one product line per call and marks the order completed immediately.
- The order procedure does not explicitly validate that quantity is an integer; fractional input can be rounded in the order-item column while a fractional amount is deducted from stock. The schema also does not automatically reconcile order totals with line items.

These points are useful topics for extending the assignment, but the current project remains a focused educational demonstration rather than a complete real-world retail system.
