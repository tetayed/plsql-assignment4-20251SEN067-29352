-- DROP IF THEY EXIST INORDER TO MINIMIZE ERRORS WHEN CREATING TABLES
DROP TABLE order_items CASCADE CONSTRAINTS;
DROP TABLE orders CASCADE CONSTRAINTS;
DROP TABLE products CASCADE CONSTRAINTS;
DROP TABLE customers CASCADE CONSTRAINTS;

-- CREATE TABLES OF OUR SYSTSEM
-- 1. CUSTOMERS TABLES
CREATE TABLE customers (
    customer_id  NUMBER(10) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    loyalty_points NUMBER(6) DEFAULT 0,
    created_at DATE DEFAULT SYSDATE
);

-- 2. PRODUCTS TABLE
CREATE TABLE products (
    product_id NUMBER(10) PRIMARY KEY,
    product_name VARCHAR2(100) NOT NULL,
    unit_price NUMBER(10, 2) NOT NULL,
    stock_quantity NUMBER(6) NOT NULL,
    CONSTRAINT chk_stock_positive CHECK (stock_quantity >= 0),
    CONSTRAINT chk_price_positive CHECK (unit_price > 0)
);

-- 3. ORDERS TABLE
CREATE TABLE orders (
    order_id NUMBER(10) PRIMARY KEY,
    customer_id  NUMBER(10) NOT NULL,
    order_date DATE DEFAULT SYSDATE NOT NULL,
    total_amount NUMBER(10, 2) DEFAULT 0,
    ord_status VARCHAR2(20) DEFAULT 'PENDING' NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id),
    CONSTRAINT chk_order_status CHECK (ord_status IN ('PENDING', 'COMPLETED', 'CANCELLED'))
);

-- 4. ORDER_ITEMS TABLE
CREATE TABLE order_items (
    item_id  NUMBER(10) PRIMARY KEY,
    order_id  NUMBER(10) NOT NULL,
    product_id  NUMBER(10) NOT NULL,
    quantity  NUMBER(4) NOT NULL,
    unit_price  NUMBER(10, 2) NOT NULL,
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_items_product FOREIGN KEY (product_id) 
        REFERENCES products(product_id),
    CONSTRAINT chk_qty_positive CHECK (quantity > 0)
);