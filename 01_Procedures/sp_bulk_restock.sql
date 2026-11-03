-- PURPOSE OF THIS PROCEDURE:
-- This procedure performs a bulk restock of products that have stock quantities below a specified threshold.


CREATE OR REPLACE PROCEDURE sp_bulk_restock (
    p_threshold IN NUMBER,
    p_add_qty   IN NUMBER
) IS
    -- 1. Define a Collection Type (Nested Table)
    TYPE t_product_id_list IS TABLE OF products.product_id%TYPE;
    v_low_stock_ids t_product_id_list;

    -- Exception for BULK DML errors
    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
BEGIN
    -- 2. BULK COLLECT low-stock product IDs into collection
    SELECT product_id
    BULK COLLECT INTO v_low_stock_ids
    FROM products
    WHERE stock_quantity <= p_threshold;

    IF v_low_stock_ids.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No products require restocking below threshold: ' || p_threshold);
        RETURN;
    END IF;

    -- 3. FORALL bulk update with SAVE EXCEPTIONS
    FORALL i IN 1..v_low_stock_ids.COUNT SAVE EXCEPTIONS
        UPDATE products
        SET stock_quantity = stock_quantity + p_add_qty
        WHERE product_id = v_low_stock_ids(i);

    -- Implicit Cursor check
    DBMS_OUTPUT.PUT_LINE('Successfully restocked ' || SQL%ROWCOUNT || ' low-stock items.');

EXCEPTION
    WHEN e_bulk_errors THEN
        DBMS_OUTPUT.PUT_LINE('Bulk operation encountered errors: ' || SQL%BULK_EXCEPTIONS.COUNT);
        FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('Error #' || i || ' Index: ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX ||
                                 ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
        END LOOP;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Unhandled error during bulk restocking.');
END sp_bulk_restock;
/