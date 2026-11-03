-- THE PURPOSE OF THIS PROCEDURE:
-- This procedure processes a customer order by validating stock availability,
-- calculating totals and discounts, inserting order



CREATE OR REPLACE PROCEDURE sp_process_order (
    p_customer_id IN NUMBER,
    p_product_id  IN NUMBER,
    p_quantity    IN NUMBER
) IS
    -- 1. Declare %ROWTYPE records
    v_product_rec  products%ROWTYPE;
    
    v_new_order_id NUMBER;
    v_new_item_id  NUMBER;
    v_item_total   NUMBER(10, 2);
    v_discount     NUMBER(10, 2);
    v_final_total  NUMBER(10, 2);

    -- Custom Exception
    e_insufficient_stock EXCEPTION;
BEGIN
    -- Fetch product details into %ROWTYPE record
    SELECT * INTO v_product_rec
    FROM products
    WHERE product_id = p_product_id;

    -- Stock Validation
    IF v_product_rec.stock_quantity < p_quantity THEN
        RAISE e_insufficient_stock;
    END IF;

    -- Calculate Totals & Apply Discount Function
    v_item_total  := v_product_rec.unit_price * p_quantity;
    v_discount    := fn_calculate_discount(p_customer_id, v_item_total);
    v_final_total := v_item_total - v_discount;

    -- Generate Primary Keys
    SELECT NVL(MAX(order_id), 500) + 1 INTO v_new_order_id FROM orders;
    SELECT NVL(MAX(item_id), 1000) + 1 INTO v_new_item_id FROM order_items;

    -- Insert Order Header
    INSERT INTO orders (order_id, customer_id, order_date, total_amount, ord_status)
    VALUES (v_new_order_id, p_customer_id, SYSDATE, v_final_total, 'COMPLETED');

    -- Insert Order Item
    INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price)
    VALUES (v_new_item_id, v_new_order_id, p_product_id, p_quantity, v_product_rec.unit_price);

    -- Update Product Inventory
    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id;

    -- Implicit cursor attribute validation
    IF SQL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Order ' || v_new_order_id || ' processed successfully.');
    END IF;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Product or Customer ID not found.');
    WHEN e_insufficient_stock THEN
        RAISE_APPLICATION_ERROR(-20006, 'Order Failed: Insufficient stock available for Product ID ' || p_product_id);
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_process_order;
/