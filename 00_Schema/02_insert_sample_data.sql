-- Insert all sample customers in one statement
INSERT ALL
	INTO customers (customer_id, customer_name, email, loyalty_points)
		VALUES (1, 'Alice Uwase', 'alice@example.com', 120)
	INTO customers (customer_id, customer_name, email, loyalty_points)
		VALUES (2, 'Bob Mugisha', 'bob@example.com', 45)
	INTO customers (customer_id, customer_name, email, loyalty_points)
		VALUES (3, 'Chantal Niyonsaba', 'chantal@example.com', 200)
	INTO customers (customer_id, customer_name, email, loyalty_points)
		VALUES (4, 'David Habimana', 'david@example.com', 0)
	INTO customers (customer_id, customer_name, email, loyalty_points)
		VALUES (5, 'Emmanuel Kwizera', 'emmanuel@example.com', 85)
SELECT * FROM dual;

-- Insert all sample products; includes low-stock items for restock tests
INSERT ALL
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (101, 'Inyange Whole Milk 1L', 1200.00, 50)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (102, 'Gorilla Coffee 250g', 4500.00, 5)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (103, 'Kinazi Cassava Flour 2kg', 2500.00, 30)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (104, 'Azam Wheat Flour 1kg', 1500.00, 3)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (105, 'Akabanga Chilli Oil 100ml', 1000.00, 100)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (106, 'Rwandan Tea Bags 100s', 3000.00, 2)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (107, 'Basmati Rice 5kg', 8500.00, 20)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (108, 'Minerval Mineral Water 1.5L', 600.00, 150)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (109, 'Sunflower Cooking Oil 1L', 3200.00, 15)
	INTO products (product_id, product_name, unit_price, stock_quantity)
		VALUES (110, 'White Sugar 1kg', 1400.00, 40)
SELECT * FROM dual;

-- Insert the order before its dependent order items
INSERT ALL
	INTO orders (order_id, customer_id, order_date, total_amount, ord_status)
		VALUES (501, 1, SYSDATE - 2, 5700.00, 'COMPLETED')
SELECT * FROM dual;

INSERT ALL
	INTO order_items (item_id, order_id, product_id, quantity, unit_price)
		VALUES (1001, 501, 101, 1, 1200.00)
	INTO order_items (item_id, order_id, product_id, quantity, unit_price)
		VALUES (1002, 501, 102, 1, 4500.00)
SELECT * FROM dual;

COMMIT;
