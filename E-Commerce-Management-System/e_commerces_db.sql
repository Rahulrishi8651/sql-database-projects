-- ??????????????????????????????????????????????????????????
-- PROJECT 1: E-COMMERCE MANAGEMENT SYSTEM
-- Business Logic: Online retail platform. Customers order
-- products, stock is auto-reduced, payments tracked.
-- Admins monitor revenue, ratings, and stock via audit logs.
-- ??????????????????????????????????????????????????????????

CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- ??? TABLES ????????????????????????????????????????????????

CREATE TABLE customers (
    customer_id   INT IDENTITY(1,1) PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    phone         VARCHAR(15),
    address       varchar(Max),
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id   INT IDENTITY(1,1) PRIMARY KEY,
    name          VARCHAR(50) NOT NULL,
    description   TEXT
);

CREATE TABLE products (
    product_id    INT IDENTITY(1,1) PRIMARY KEY,
    name          VARCHAR(150) NOT NULL,
    category_id   INT,
    price         DECIMAL(10,2) NOT NULL,
    stock_qty     INT DEFAULT 0,
    description   TEXT,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id      INT IDENTITY(1,1) PRIMARY KEY, 
    customer_id   INT NOT NULL,
    order_date    DATETIME DEFAULT CURRENT_TIMESTAMP, -- or DEFAULT GETDATE()
    status        VARCHAR(20) DEFAULT 'pending' 
                  CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled')),
    total_amount  DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


CREATE TABLE order_items (
    item_id       INT IDENTITY(1,1) PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id   INT NOT NULL,
    amount     DECIMAL(10,2) NOT NULL,
    
    -- Payment method restricted via CHECK constraint
    method     VARCHAR(20) NOT NULL
               CHECK (method IN ('credit_card','debit_card','upi','cod','netbanking')),
    
    -- Payment status restricted via CHECK constraint
    status     VARCHAR(20) DEFAULT 'pending'
               CHECK (status IN ('pending','completed','failed','refunded')),
    
    paid_at    DATETIME, -- You can set DEFAULT GETDATE() if needed
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


CREATE TABLE reviews (
    review_id     INT IDENTITY(1,1) PRIMARY KEY,
    product_id    INT NOT NULL,
    customer_id   INT NOT NULL,
    rating        TINYINT CHECK (rating BETWEEN 1 AND 5),
    comment       TEXT,
    reviewed_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Audit log for tracking all stock level changes
CREATE TABLE stock_audit (
    audit_id      INT IDENTITY(1,1) PRIMARY KEY,
    product_id    INT,
    old_stock     INT,
    new_stock     INT,
    changed_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    action_type   VARCHAR(50)
);

-- ??? SAMPLE DATA ???????????????????????????????????????????

INSERT INTO categories (name, description) VALUES
('Electronics',   'Gadgets and electronic devices'),
('Clothing',      'Apparel and fashion'),
('Books',         'Educational and fiction books'),
('Home & Kitchen','Household items and appliances');

INSERT INTO customers (full_name, email, phone, address) VALUES
('Ananya Sharma', 'ananya@email.com', '9876543210', 'Delhi'),
('Rohit Verma',   'rohit@email.com',  '9812345678', 'Mumbai'),
('Priya Singh',   'priya@email.com',  '9988776655', 'Bangalore'),
('Arun Patel',    'arun@email.com',   '9001234567', 'Chennai'),
('Neha Gupta',    'neha@email.com',   '9123456780', 'Kolkata');

INSERT INTO products (name, category_id, price, stock_qty) VALUES
('Samsung Galaxy M34',  1, 18999.00,  50),
('Apple AirPods Pro',   1, 24999.00,  30),
('Mens Formal Shirt',   2,  1299.00, 100),
('Clean Code Book',     3,   499.00, 200),
('Instant Pot 6Qt',     4,  7999.00,  25),
('Wireless Mouse',      1,   799.00,  75),
('Python Crash Course', 3,   599.00, 150);

INSERT INTO orders (customer_id, status, total_amount) VALUES
(1,'delivered', 19798.00),
(2,'shipped',   25798.00),
(3,'confirmed',  1898.00),
(4,'pending',    7999.00),
(1,'delivered',   599.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,1,1,18999.00),(1,6,1,799.00),
(2,2,1,24999.00),(2,4,2,499.00),
(3,3,1,1299.00), (3,4,1,499.00),
(4,5,1,7999.00),
(5,7,1,599.00);

INSERT INTO payments (order_id, amount, method, status, paid_at) VALUES
(1,19798.00,'upi','completed',GETDATE()),
(2,25798.00,'credit_card','completed',GETDATE()),
(3,1898.00,'netbanking','completed',GETDATE()),
(4,7999.00,'cod','pending',NULL),
(5,599.00,'debit_card','completed',GETDATE());

INSERT INTO reviews (product_id, customer_id, rating, comment) VALUES
(1,1,5,'Excellent phone!'),
(2,2,4,'Good sound quality'),
(7,1,5,'Perfect for beginners'),
(4,3,4,'Very insightful');

-- ??? UPDATE ????????????????????????????????????????????????

UPDATE orders 
SET status = 'delivered' 
WHERE order_id = 2;

UPDATE products 
SET price = ROUND(price * 0.90, 2) 
WHERE category_id = 3; -- 10% discount

UPDATE payments
SET status = 'completed',
    paid_at = GETDATE()
WHERE order_id = 4 
AND status = 'pending';

-- ??? DELETE ????????????????????????????????????????????????

DELETE FROM orders
WHERE status = 'cancelled'
AND order_date < DATEADD(DAY, -30, GETDATE());

-- ??? SELECT Q1: Customer spending summary ??????????????????
-- INNER JOIN + GROUP BY + HAVING + ORDER BY

SELECT
    c.full_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    MAX(p.status) AS payment_status
FROM customers c
INNER JOIN orders o 
    ON c.customer_id = o.customer_id
INNER JOIN payments p 
    ON o.order_id = p.order_id
GROUP BY c.customer_id, c.full_name, c.email
HAVING SUM(o.total_amount) > 1000
ORDER BY total_spent DESC;

-- ??? SELECT Q2: Products with avg rating (incl. unreviewed)
-- LEFT JOIN + GROUP BY + ORDER BY

SELECT
    p.name AS product_name,
    cat.name AS category,
    p.price,
    p.stock_qty,
    ROUND(AVG(r.rating),2) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM products p
INNER JOIN categories cat 
    ON p.category_id = cat.category_id
LEFT JOIN reviews r 
    ON p.product_id = r.product_id
GROUP BY p.product_id, p.name, cat.name, p.price, p.stock_qty
ORDER BY avg_rating DESC;

-- ??? SELECT Q3: Monthly revenue report ?????????????????????

SELECT
    FORMAT(o.order_date,'yyyy-MM') AS month,
    COUNT(DISTINCT o.order_id) AS orders_placed,
    SUM(oi.quantity) AS items_sold,
    SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM orders o
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY FORMAT(o.order_date,'yyyy-MM')
HAVING SUM(oi.quantity * oi.unit_price) > 0
ORDER BY month DESC;

-- ??? SUBQUERY 1: Above-average spenders ????????????????????

SELECT full_name, email
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    WHERE total_amount >
    (SELECT AVG(total_amount) FROM orders)
);

-- ??? SUBQUERY 2: Products never ordered ????????????????????

SELECT name, price
FROM products
WHERE product_id NOT IN
(
    SELECT DISTINCT product_id 
    FROM order_items
);

-- ??? STORED PROCEDURE ??????????????????????????????????????

CREATE PROCEDURE PlaceOrder
    @p_customer_id INT,
    @p_product_id INT,
    @p_quantity INT,
    @p_order_id INT OUTPUT,
    @p_message VARCHAR(200) OUTPUT
AS
BEGIN

DECLARE @v_stock INT
DECLARE @v_price DECIMAL(10,2)
DECLARE @v_total DECIMAL(10,2)

SELECT 
    @v_stock = stock_qty,
    @v_price = price
FROM products
WHERE product_id = @p_product_id

IF @v_stock IS NULL
BEGIN
    SET @p_message = 'ERROR: Product not found'
    SET @p_order_id = 0
END

ELSE IF @v_stock < @p_quantity
BEGIN
    SET @p_message = 'ERROR: Not enough stock'
    SET @p_order_id = 0
END

ELSE
BEGIN
    SET @v_total = @v_price * @p_quantity

    INSERT INTO orders(customer_id,status,total_amount)
    VALUES(@p_customer_id,'confirmed',@v_total)

    SET @p_order_id = SCOPE_IDENTITY()

    INSERT INTO order_items(order_id,product_id,quantity,unit_price)
    VALUES(@p_order_id,@p_product_id,@p_quantity,@v_price)

    UPDATE products
    SET stock_qty = stock_qty - @p_quantity
    WHERE product_id = @p_product_id

    SET @p_message = 'SUCCESS: Order placed'
END

END

--call the produce
DECLARE @oid INT
DECLARE @msg VARCHAR(200)

EXEC PlaceOrder 3,1,2,@oid OUTPUT,@msg OUTPUT

SELECT @oid,@msg
-- CALL PlaceOrder(3, 1, 2, @oid, @msg); SELECT @oid, @msg;

-- ??? TRIGGER ???????????????????????????????????????????????

CREATE TRIGGER trg_stock_audit
ON products
AFTER UPDATE
AS
BEGIN

INSERT INTO stock_audit(product_id, old_stock, new_stock, action_type)
SELECT
    d.product_id,
    d.stock_qty,
    i.stock_qty,
    CASE 
        WHEN i.stock_qty < d.stock_qty THEN 'STOCK_REDUCED'
        ELSE 'STOCK_ADDED'
    END
FROM deleted d
JOIN inserted i
ON d.product_id = i.product_id
WHERE d.stock_qty <> i.stock_qty

END

-- ??? VIEW ??????????????????????????????????????????????????

CREATE OR ALTER VIEW vw_order_details AS
SELECT
    o.order_id,
    c.full_name AS customer_name,
    p.name AS product_name,
    cat.name AS category,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total,
    o.status,
    o.order_date
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
INNER JOIN order_items oi
    ON o.order_id = oi.order_id
INNER JOIN products p
    ON oi.product_id = p.product_id
INNER JOIN categories cat
    ON p.category_id = cat.category_id;

-- ??? INDEXES ???????????????????????????????????????????????

CREATE INDEX idx_orders_customer
ON orders(customer_id);

CREATE INDEX idx_order_items_order
ON order_items(order_id);

CREATE INDEX idx_order_items_product
ON order_items(product_id);

CREATE INDEX idx_products_category
ON products(category_id);

-- ??? CTE: Top 3 customers by spending with RANK() ??????????

WITH customer_spending AS
(
SELECT
    c.customer_id,
    c.full_name,
    SUM(o.total_amount) AS total_spent
FROM customers c
INNER JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.status <> 'cancelled'
GROUP BY c.customer_id,c.full_name
),
ranked AS
(
SELECT *,
RANK() OVER(ORDER BY total_spent DESC) AS rnk
FROM customer_spending
)

SELECT *
FROM ranked
WHERE rnk <= 3;