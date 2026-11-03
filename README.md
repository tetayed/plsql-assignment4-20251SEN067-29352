# Assignment IV: Retail Order & Inventory Management System (PL/SQL)

**Course:** Database Development with PL/SQL (INSY 8311)  
**Institution:** Adventist University of Central Africa (AUCA)  
**Instructor:** Eric Maniraguha | **Teaching Assistant:** Afanyu Emmanuel  

---

##  Group Members

| Student Name | Student ID |
| :--- | :--- |
| **Student 1** | `20251SEN067` |
| **Student 2** | `29352` |

---

##  Business Scenario Overview

This project implements a realistic database back-end for a supermarket and retail supply chain (**Sunrise Supermarket**). The system automates inventory control, customer loyalty discount management, order fulfillment, and high-performance bulk restocking operations.

The application leverages advanced Oracle PL/SQL concepts including:
* **PL/SQL Records:** User-defined composite records and `%ROWTYPE` record structures.
* **Collections:** Dynamic PL/SQL Nested Tables (`TABLE OF`).
* **Cursors:** Explicit Cursors (`OPEN`/`FETCH`/`CLOSE`) and Implicit Cursors (`SQL%FOUND`, `SQL%ROWCOUNT`).
* **Bulk Processing:** High-performance data retrieval and manipulation using `BULK COLLECT` and `FORALL` with `SAVE EXCEPTIONS` error handling.
* **Stored Procedures & Functions:** Modular design with strict input/output parameter handling.
* **Robust Exception Handling:** Predefined system exceptions (`NO_DATA_FOUND`), custom user-defined exceptions, and standard user alerts via `RAISE_APPLICATION_ERROR`.

---

##  Repository Structure

```text
plsql-assignment4-20251SEN067-29352/
├── README.md
├── .gitignore
├── 00_schema/
│   ├── 01_create_tables.sql
│   └── 02_insert_sample_data.sql
├── 01_procedures/
│   ├── sp_bulk_restock.sql
│   └── sp_process_order.sql
├── 02_functions/
│   ├── fn_calculate_discount.sql
│   └── fn_check_stock.sql
├── 03_tests/
│   ├── test_success_cases.sql
│   └── test_error_cases.sql
├── screenshots/
│   ├── 01_schema_and_data.png
│   ├── 02_compilation_success.png
│   ├── 03_test_success_output.png
│   └── 04_test_error_output.png
└── docs/
    └── IMPLEMENTATION_NOTES.md
```

---

##  Step-by-Step Execution Guide

Follow these steps sequentially in Oracle SQL Developer, SQL*Plus, or VS Code Oracle Extension:

1. **Enable Server Output**  
   Ensure terminal output is active:
   ```sql
   SET SERVEROUTPUT ON;
   ```

2. **Database Schema & Data Initialization**  
   Run the table creation script followed by the sample data insertion script:
   ```sql
   @00_schema/01_create_tables.sql
   @00_schema/02_insert_sample_data.sql
   ```

3. **Compile Stored Functions**  
   Compile the utility functions into the schema:
   ```sql
   @02_functions/fn_calculate_discount.sql
   @02_functions/fn_check_stock.sql
   ```

4. **Compile Stored Procedures**  
   Compile the transactional procedures into the schema:
   ```sql
   @01_procedures/sp_bulk_restock.sql
   @01_procedures/sp_process_order.sql
   ```

5. **Execute Test Cases & Verify Results**  
   Execute the success and error test suites to verify functionality and error handling:
   ```sql
   @03_tests/test_success_cases.sql
   @03_tests/test_error_cases.sql
   ```

---

##  AI Assistance Disclosure

In compliance with academic integrity guidelines, an AI assistant (Gemini) was utilized during this assignment as a writing coach and workflow planner. Specific uses included:
* Planning task workflows and execution checklists.
* Formatting and structuring technical repository documentation (`README.md` and `IMPLEMENTATION_NOTES.md`).
* Debugging Oracle PL/SQL compilation messages and constraint error codes (e.g., `ORA-00933`, `ORA-00001`).

*Both group members reviewed, executed, fully understand, and remain responsible for all submitted PL/SQL code and architectural implementations.*