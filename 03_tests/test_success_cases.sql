SET SERVEROUTPUT ON;

-- Test 1: Verify fn_calculate_discount
DECLARE
    v_discount NUMBER;
BEGIN
    v_discount := fn_calculate_discount(p_customer_id => 1, p_subtotal => 10000);
    DBMS_OUTPUT.PUT_LINE('Test 1 Passed - Calculated Discount: RWF ' || v_discount);
END;
/

-- Test 2: Process a Valid Order (sp_process_order)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Before Order Processing ---');
    -- Process order for Customer 1 purchasing 2 units of Product 101
    sp_process_order(p_customer_id => 1, p_product_id => 101, p_quantity => 2);
END;
/

-- Verify table changes after order
SELECT * FROM orders WHERE order_id = (SELECT MAX(order_id) FROM orders);
SELECT * FROM order_items WHERE order_id = (SELECT MAX(order_id) FROM orders);
SELECT product_id, stock_quantity FROM products WHERE product_id = 101;

-- Test 3: Bulk Restock Low Inventory Items (sp_bulk_restock)
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Testing Bulk Restock ---');
    sp_bulk_restock(p_threshold => 10, p_add_qty => 50);
END;
/

-- Verify bulk restock results
SELECT product_id, product_name, stock_quantity FROM products WHERE product_id IN (102, 104, 106);