-- THE PURPOSE OF THIS FUNCTION IS TO CALCULATE THE DISCOUNT OF A CUSTOMER'S ORDER BASED ON THE LOYAL POINTS

CREATE OR REPLACE FUNCTION fn_calculate_discount (
    p_customer_id IN NUMBER,
    p_subtotal    IN NUMBER
) RETURN NUMBER IS
    -- 1. Declaration of a User-Defined Record Type
    TYPE customer_discount_rec IS RECORD (
        cust_id        NUMBER,
        points         NUMBER,
        discount_rate  NUMBER(3, 2)
    );
    
    v_cust_rec customer_discount_rec;
    v_discount NUMBER(10, 2) := 0;

    -- 2. Declaration of an Explicit Cursor
    CURSOR c_customer IS
        SELECT customer_id, loyalty_points
        FROM customers
        WHERE customer_id = p_customer_id;

    -- User-defined exception
    e_invalid_subtotal EXCEPTION;

BEGIN
    -- Input Validation Exception Handling
    IF p_subtotal <= 0 THEN
        RAISE e_invalid_subtotal;
    END IF;

    -- Open, Fetch, and Close Explicit Cursor
    OPEN c_customer;
    FETCH c_customer INTO v_cust_rec.cust_id, v_cust_rec.points;
    
    IF c_customer%NOTFOUND THEN
        CLOSE c_customer;
        RAISE_APPLICATION_ERROR(-20001, 'Error: Customer ID ' || p_customer_id || ' does not exist.');
    END IF;
    CLOSE c_customer;

    -- Determine discount rate based on loyalty points
    IF v_cust_rec.points >= 150 THEN
        v_cust_rec.discount_rate := 0.15; -- 15% discount
    ELSIF v_cust_rec.points >= 50 THEN
        v_cust_rec.discount_rate := 0.05; -- 5% discount
    ELSE
        v_cust_rec.discount_rate := 0.00; -- No discount
    END IF;

    v_discount := p_subtotal * v_cust_rec.discount_rate;
    RETURN v_discount;

EXCEPTION
    WHEN e_invalid_subtotal THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error: Order subtotal must be greater than zero.');
    WHEN OTHERS THEN
        IF c_customer%ISOPEN THEN
            CLOSE c_customer;
        END IF;
        RAISE;
END fn_calculate_discount;
/