SET SERVEROUTPUT ON;

-- Test 1: Order Quantity Exceeds Available Stock (e_insufficient_stock)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Error Test 1: Insufficient Stock ---');
    sp_process_order(p_customer_id => 1, p_product_id => 103, p_quantity => 9999);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Caught Expected Error: ' || SQLERRM);
END;
/

-- Test 2: Non-Existent Customer ID
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Error Test 2: Invalid Customer ---');
    sp_process_order(p_customer_id => 9999, p_product_id => 101, p_quantity => 1);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Caught Expected Error: ' || SQLERRM);
END;
/

-- Test 3: Negative Order Subtotal
DECLARE
    v_discount NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Error Test 3: Invalid Subtotal ---');
    v_discount := fn_calculate_discount(p_customer_id => 1, p_subtotal => -500);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Caught Expected Error: ' || SQLERRM);
END;
/