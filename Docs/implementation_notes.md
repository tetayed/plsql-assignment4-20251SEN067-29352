# Technical Implementation & Performance Notes

**Course:** Database Development with PL/SQL (INSY 8311)  
**Application Domain:** Retail Order & Inventory Management System (Sunrise Supermarket)  
**Student IDs:** `20251SEN067` | `29352`

---

## 1. System Architecture & PL/SQL Features Overview

The application is engineered to handle core supermarket operations—such as order placement, stock verification, customer loyalty discounts, and bulk inventory restocking—using clean, modular Oracle PL/SQL constructs.

### Core PL/SQL Components Used

1. **PL/SQL Records (`%ROWTYPE` and User-Defined)**
   * **`%ROWTYPE`:** Used inside `sp_process_order` to fetch and hold complete product table rows (`v_product_rec products%ROWTYPE;`), guaranteeing strong typing aligned directly with database table structures.
   * **User-Defined Records:** Implemented inside `fn_calculate_discount` using `TYPE customer_discount_rec IS RECORD(...)` to group customer IDs, points, and dynamic discount rates into a single composite object.

2. **Collections (Nested Tables)**
   * Implemented dynamic collections (`TYPE t_product_id_list IS TABLE OF products.product_id%TYPE;`) inside `sp_bulk_restock`.
   * Collections store sets of product IDs retrieved dynamically from queries to facilitate high-speed bulk database operations.

3. **Explicit & Implicit Cursors**
   * **Explicit Cursors:** Used in `fn_calculate_discount` (`CURSOR c_customer IS SELECT ...`) with explicit control flow (`OPEN`, `FETCH`, `CLOSE`, `%NOTFOUND`) to safely validate customer eligibility.
   * **Implicit Cursors:** Utilized across DML operations in procedures to assess attributes like `SQL%ROWCOUNT` (to confirm updated row counts) and `SQL%FOUND`.

---

## 2. Bulk Processing & Performance Optimization

### The Problem: Row-by-Row Processing (Slow-by-Slow)
In traditional PL/SQL implementations, updating multiple records involves iterating over explicit cursor loops and executing separate DML (`UPDATE`/`INSERT`) statements for each iteration:

```sql
-- Standard (Inefficient) Row-by-Row Processing
FOR rec IN (SELECT product_id FROM products WHERE stock_quantity <= 10) LOOP
    UPDATE products SET stock_quantity = stock_quantity + 50 WHERE product_id = rec.product_id;
END LOOP;
```

Each iteration forces the Oracle Database engine to perform a **context switch** between the **PL/SQL Engine** (procedural logic execution) and the **SQL Engine** (database data manipulation). Across thousands of records, context switching creates significant CPU overhead and decreases transaction throughput.

### The Solution: `BULK COLLECT` and `FORALL`
In `sp_bulk_restock`, bulk processing eliminates context switching by transferring data between engines in unified batches:

1. **`BULK COLLECT`:** Reads multiple database rows into a PL/SQL collection in a single context switch.
2. **`FORALL`:** Passes the entire collection array from the PL/SQL engine back to the SQL engine in a single batch DML request.

```
+-------------------+      BULK COLLECT (1 Switch)     +-------------------+
|  SQL DB Engine    |  ============================>   |   PL/SQL Engine   |
|  (products table) |  <============================   |   (Collection)    |
+-------------------+       FORALL DML (1 Switch)      +-------------------+
```

### Performance Benefits Summary
* **Reduced Context Switching:** Reduces thousands of individual engine hand-offs down to two.
* **Lower CPU Overhead:** Significantly decreases execution times and resource contention on production servers.
* **Network Latency Minimization:** Highly effective when application servers interact with remote database servers.

---

## 3. Exception Handling Strategy

The database application enforces strict data integrity constraints using a three-tiered exception-handling architecture:

### 1. Predefined System Exceptions
Standard system-level errors are trapped to prevent raw database failures from bubbling up unhandled:
* **`NO_DATA_FOUND`:** Caught in `fn_check_stock` and `sp_process_order` when query targets (such as invalid customer or product IDs) do not exist.

### 2. User-Defined Exceptions & `RAISE_APPLICATION_ERROR`
Custom business rules trigger explicit exception branches with descriptive error codes and readable messages:
* **`e_insufficient_stock`:** Triggered in `sp_process_order` if requested purchase quantity exceeds available product stock level. Formatted using `RAISE_APPLICATION_ERROR(-20006, ...)`.
* **`e_invalid_subtotal`:** Triggered in `fn_calculate_discount` when negative or zero order totals are passed. Formatted using `RAISE_APPLICATION_ERROR(-20002, ...)`.

### 3. Bulk DML Error Handling (`SAVE EXCEPTIONS`)
Bulk DML operations use the `SAVE EXCEPTIONS` clause within `FORALL` blocks:
* If one record update fails in a bulk batch (e.g., violating a check constraint), Oracle does **not** terminate the whole batch.
* Instead, Oracle saves error details into the pseudo-collection `SQL%BULK_EXCEPTIONS`, allows valid records to complete, and exposes individual error codes (`ERROR_CODE`) and array indices (`ERROR_INDEX`) for granular reporting.

---

## 4. Database Integrity & Transaction Control

* **Explicit Transaction Boundaries:** Procedures performing DML operations handle transactions cleanly (`COMMIT` upon success; `ROLLBACK` in exception blocks) to keep table data synchronized.
* **Cascade & Foreign Key Safeguards:** Orders and line items maintain referential integrity with cascading deletes configured appropriately (`ON DELETE CASCADE` on line items).