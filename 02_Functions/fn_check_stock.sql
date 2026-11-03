-- THE PURPOSE OF THIS FUNCTION IS TO CHECK IF THE REQUESTED QUANTITY OF A PRODUCT IS AVAILABLE IN STOCK
-- USING IMPLICITY CURSOR SQL%FOUND AND RERTUNING CURRENT STOCK COUNT


CREATE OR REPLACE FUNCTION fn_check_stock (
    p_product_id IN NUMBER,
    p_req_qty    IN NUMBER
) RETURN BOOLEAN IS
    v_current_stock NUMBER;
BEGIN
    SELECT stock_quantity
    INTO v_current_stock
    FROM products
    WHERE product_id = p_product_id;

    IF v_current_stock >= p_req_qty THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error: Product ID ' || p_product_id || ' not found.');
END fn_check_stock;
/