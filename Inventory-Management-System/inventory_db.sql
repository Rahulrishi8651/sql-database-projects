-- ??????????????????????????????????????????????????????????
-- PROJECT 5: INVENTORY MANAGEMENT SYSTEM
-- Platform : Microsoft SQL Server (T-SQL)
-- Business Logic: Warehouse tracking for products, POs,
-- and SOs. Stock deducted on sale. Reorder alert fires
-- automatically via trigger. ABC analysis classifies
-- products by 80/15/5 Pareto revenue contribution.
-- ??????????????????????????????????????????????????????????

-- Create and switch to database
-- IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'inventory_db')
    CREATE DATABASE inventory_db;
GO
USE inventory_db;
GO

-- ??? TABLES ????????????????????????????????????????????????

CREATE TABLE suppliers (
    supplier_id  INT IDENTITY(1,1) PRIMARY KEY,
    name         NVARCHAR(150) NOT NULL,
    contact_name NVARCHAR(100),
    email        NVARCHAR(100),
    phone        NVARCHAR(15),
    city         NVARCHAR(50),
    rating       DECIMAL(3,1) DEFAULT 3.0
);
GO

CREATE TABLE inv_categories (
    cat_id      INT IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(80),
    description NVARCHAR(MAX)
);
GO

CREATE TABLE products_inv (
    product_id    INT IDENTITY(1,1) PRIMARY KEY,
    sku           NVARCHAR(30) NOT NULL UNIQUE,
    name          NVARCHAR(150),
    cat_id        INT,
    unit          NVARCHAR(20),
    cost_price    DECIMAL(10,2),
    selling_price DECIMAL(10,2),
    stock_qty     INT DEFAULT 0,
    reorder_level INT DEFAULT 10,
    max_stock     INT DEFAULT 500,
    CONSTRAINT fk_prod_cat FOREIGN KEY (cat_id)
        REFERENCES inv_categories(cat_id)
);
GO

CREATE TABLE purchase_orders (
    po_id         INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id   INT NOT NULL,
    order_date    DATETIME DEFAULT GETDATE(),
    expected_date DATE,
    -- SQL Server uses NVARCHAR instead of ENUM
    status        NVARCHAR(20) DEFAULT 'draft'
                  CHECK (status IN ('draft','sent','received','cancelled')),
    total_value   DECIMAL(12,2) DEFAULT 0.00,
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
);
GO

CREATE TABLE po_items (
    po_item_id   INT IDENTITY(1,1) PRIMARY KEY,
    po_id        INT,
    product_id   INT,
    quantity     INT,
    unit_cost    DECIMAL(10,2),
    received_qty INT DEFAULT 0,
    CONSTRAINT fk_poi_po      FOREIGN KEY (po_id)
        REFERENCES purchase_orders(po_id),
    CONSTRAINT fk_poi_product FOREIGN KEY (product_id)
        REFERENCES products_inv(product_id)
);
GO

CREATE TABLE sales_orders (
    so_id         INT IDENTITY(1,1) PRIMARY KEY,
    customer_name NVARCHAR(150),
    order_date    DATETIME DEFAULT GETDATE(),
    status        NVARCHAR(20) DEFAULT 'pending'
                  CHECK (status IN ('pending','fulfilled','partial','cancelled')),
    total_value   DECIMAL(12,2) DEFAULT 0.00
);
GO

CREATE TABLE so_items (
    so_item_id INT IDENTITY(1,1) PRIMARY KEY,
    so_id      INT,
    product_id INT,
    quantity   INT,
    unit_price DECIMAL(10,2),
    CONSTRAINT fk_soi_so      FOREIGN KEY (so_id)
        REFERENCES sales_orders(so_id),
    CONSTRAINT fk_soi_product FOREIGN KEY (product_id)
        REFERENCES products_inv(product_id)
);
GO

CREATE TABLE stock_movements (
    movement_id   INT IDENTITY(1,1) PRIMARY KEY,
    product_id    INT,
    movement_type NVARCHAR(20)
                  CHECK (movement_type IN ('purchase','sale','adjustment','return')),
    quantity      INT,
    reference_id  INT,
    moved_at      DATETIME DEFAULT GETDATE(),
    notes         NVARCHAR(200)
);
GO

CREATE TABLE reorder_log (
    reorder_id       INT IDENTITY(1,1) PRIMARY KEY,
    product_id       INT,
    triggered_at     DATETIME DEFAULT GETDATE(),
    stock_at_trigger INT,
    reorder_qty      INT
);
GO

-- ??? SAMPLE DATA ???????????????????????????????????????????
-- SQL Server: SET IDENTITY_INSERT ON to insert explicit IDs
-- into IDENTITY columns for categories

SET IDENTITY_INSERT inv_categories ON;
INSERT INTO inv_categories (cat_id, name, description) VALUES
(1, 'Electronics',   'Electronic components'),
(2, 'Raw Materials', 'Industrial materials'),
(3, 'Packaging',     'Boxes and wrapping'),
(4, 'Tools',         'Hand tools');
SET IDENTITY_INSERT inv_categories OFF;
GO

INSERT INTO suppliers (name, contact_name, email, phone, city, rating) VALUES
('TechParts India Pvt Ltd', 'Rakesh Gupta', 'rakesh@tp.com', '9701112222', 'Delhi',  4.5),
('FastSupply Co.',          'Anita Roy',    'anita@fs.com',  '9702223333', 'Mumbai', 4.0),
('QualityGoods Ltd',        'Sunil Menon',  'sunil@qg.com',  '9703334444', 'Pune',   3.8);
GO

INSERT INTO products_inv (sku, name, cat_id, unit, cost_price, selling_price, stock_qty, reorder_level, max_stock) VALUES
('ELEC-001', 'Arduino Uno Board',   1, 'piece',  450.00,   799.00,  80, 20, 300),
('ELEC-002', 'Raspberry Pi 4 4GB',  1, 'piece', 4500.00,  6999.00,  25,  5, 100),
('ELEC-003', '16x2 LCD Display',    1, 'piece',   95.00,   180.00, 120, 30, 500),
('RAW-001',  'Copper Wire 1kg',     2, 'kg',     280.00,   450.00,  50, 15, 200),
('PKG-001',  'Corrugated Box Sm',   3, 'piece',   12.00,    25.00, 500,100,2000),
('TOOL-001', 'Digital Multimeter',  4, 'piece',  650.00,  1200.00,  35, 10, 150);
GO

INSERT INTO purchase_orders (supplier_id, expected_date, status, total_value) VALUES
(1, '2024-02-01', 'received',  58500.00),
(2, '2024-02-15', 'received', 125000.00),
(3, '2024-03-01', 'sent',      12000.00);
GO

INSERT INTO po_items (po_id, product_id, quantity, unit_cost, received_qty) VALUES
(1, 1, 100,  450.00, 100),
(1, 3, 150,   95.00, 150),
(2, 2,  20, 4500.00,  20),
(2, 6,  50,  650.00,  50),
(3, 5,1000,   12.00,   0);
GO

INSERT INTO sales_orders (customer_name, status, total_value) VALUES
('TechStar Electronics', 'fulfilled', 47940.00),
('Innovate Labs',        'fulfilled', 76989.00),
('Campus Robotics Club', 'pending',   12740.00);
GO

INSERT INTO so_items (so_id, product_id, quantity, unit_price) VALUES
(1, 1, 30,  799.00),
(1, 3, 60,  180.00),
(2, 2, 10, 6999.00),
(2, 6,  5, 1200.00),
(3, 1, 10,  799.00),
(3, 4,  8,  450.00);
GO

-- ??? UPDATE QUERIES ????????????????????????????????????????

-- Refresh electronics selling price with 78% markup
UPDATE products_inv
SET selling_price = ROUND(cost_price * 1.78, 2)
WHERE cat_id = 1;
GO

-- Reward best-performing supplier
UPDATE suppliers
SET rating = 4.8
WHERE supplier_id = 1;
GO

-- ??? DELETE QUERY ??????????????????????????????????????????

-- Remove stale draft POs older than 60 days
-- SQL Server uses DATEADD instead of DATE_SUB
DELETE FROM purchase_orders
WHERE status = 'draft'
  AND order_date < DATEADD(DAY, -60, GETDATE());
GO

-- ??? SELECT Q1: Product Profitability Report ???????????????
-- Uses: INNER JOIN, GROUP BY, ORDER BY

SELECT
    p.sku,
    p.name,
    cat.name                                                  AS category,
    SUM(si.quantity)                                          AS units_sold,
    SUM(si.quantity * p.cost_price)                           AS total_cost,
    SUM(si.quantity * si.unit_price)                          AS total_revenue,
    SUM(si.quantity * (si.unit_price - p.cost_price))         AS gross_profit,
    ROUND(
        SUM(si.quantity * (si.unit_price - p.cost_price))
        / NULLIF(SUM(si.quantity * si.unit_price), 0) * 100
    , 2)                                                      AS margin_pct
    -- NULLIF prevents divide-by-zero (T-SQL best practice)
FROM products_inv p
INNER JOIN inv_categories cat ON p.cat_id     = cat.cat_id
INNER JOIN so_items si        ON p.product_id = si.product_id
INNER JOIN sales_orders so    ON si.so_id     = so.so_id
WHERE so.status = 'fulfilled'
GROUP BY p.product_id, p.sku, p.name, cat.name
ORDER BY gross_profit DESC;
GO

-- ??? SELECT Q2: Slow-Moving Products (no sales in 90 days) ?
-- Uses: INNER JOIN, subquery, NOT IN

SELECT
    p.sku,
    p.name,
    p.stock_qty,
    p.reorder_level,
    cat.name AS category
FROM products_inv p
INNER JOIN inv_categories cat ON p.cat_id = cat.cat_id
WHERE p.product_id NOT IN (
    SELECT DISTINCT si.product_id
    FROM so_items si
    INNER JOIN sales_orders so ON si.so_id = so.so_id
    -- SQL Server: DATEADD(DAY, -90, GETDATE()) replaces MySQL DATE_SUB
    WHERE so.order_date >= DATEADD(DAY, -90, GETDATE())
)
ORDER BY p.stock_qty DESC;
GO

-- ??? SELECT Q3: Supplier Performance Report ????????????????
-- Uses: INNER JOIN, GROUP BY, HAVING, ORDER BY

SELECT
    s.name    AS supplier,
    s.city,
    s.rating,
    COUNT(po.po_id)                                           AS total_orders,
    SUM(poi.quantity)                                         AS ordered_qty,
    SUM(poi.received_qty)                                     AS received_qty,
    ROUND(
        CAST(SUM(poi.received_qty) AS FLOAT)
        / NULLIF(SUM(poi.quantity), 0) * 100
    , 2)                                                      AS fulfillment_pct
    -- CAST to FLOAT ensures decimal division in SQL Server
FROM suppliers s
INNER JOIN purchase_orders po ON s.supplier_id = po.supplier_id
INNER JOIN po_items poi       ON po.po_id       = poi.po_id
WHERE po.status IN ('received', 'sent')
GROUP BY s.supplier_id, s.name, s.city, s.rating
HAVING ROUND(CAST(SUM(poi.received_qty) AS FLOAT)
             / NULLIF(SUM(poi.quantity),0)*100, 2) IS NOT NULL
ORDER BY fulfillment_pct DESC;
GO

-- ??? SUBQUERY 1: Products At or Below Reorder Level ????????

SELECT
    sku,
    name,
    stock_qty,
    reorder_level,
    (reorder_level - stock_qty) AS units_to_reorder
FROM products_inv
WHERE stock_qty <= reorder_level
ORDER BY (reorder_level - stock_qty) DESC;
GO

-- ??? SUBQUERY 2: Best-Selling Product by Revenue ???????????

SELECT p.name, p.sku, rev.total_revenue
FROM products_inv p
INNER JOIN (
    SELECT product_id, SUM(quantity * unit_price) AS total_revenue
    FROM so_items
    GROUP BY product_id
) rev ON p.product_id = rev.product_id
WHERE rev.total_revenue = (
    SELECT MAX(t.r)
    FROM (
        SELECT SUM(quantity * unit_price) AS r
        FROM so_items
        GROUP BY product_id
    ) t
);
GO

-- ??? STORED PROCEDURE ??????????????????????????????????????
-- SQL Server: No DELIMITER needed. Uses TRY/CATCH instead
-- of DECLARE HANDLER. Cursor syntax is similar but uses
-- FETCH NEXT and @@FETCH_STATUS instead of CONTINUE HANDLER.

CREATE OR ALTER PROCEDURE ProcessSalesOrder
    @p_so_id INT,
    @p_msg   NVARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_prod   INT;
    DECLARE @v_qty    INT;
    DECLARE @v_stock  INT;
    DECLARE @v_errors NVARCHAR(200) = '';

    -- Declare cursor over all items in this sales order
    DECLARE cur CURSOR FOR
        SELECT product_id, quantity
        FROM so_items
        WHERE so_id = @p_so_id;

    OPEN cur;

    -- SQL Server uses FETCH NEXT and checks @@FETCH_STATUS
    FETCH NEXT FROM cur INTO @v_prod, @v_qty;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @v_stock = stock_qty
        FROM products_inv
        WHERE product_id = @v_prod;

        IF @v_stock < @v_qty
        BEGIN
            -- Accumulate error message for low-stock items
            SET @v_errors = @v_errors
                + 'LOW STOCK: product_id=' + CAST(@v_prod AS NVARCHAR) + ' ';
        END
        ELSE
        BEGIN
            -- Deduct stock for this item
            UPDATE products_inv
            SET stock_qty = stock_qty - @v_qty
            WHERE product_id = @v_prod;

            -- Log the stock movement
            INSERT INTO stock_movements (product_id, movement_type, quantity, reference_id, notes)
            VALUES (@v_prod, 'sale', @v_qty, @p_so_id,
                    'SO #' + CAST(@p_so_id AS NVARCHAR));
        END

        FETCH NEXT FROM cur INTO @v_prod, @v_qty;
    END

    CLOSE cur;
    DEALLOCATE cur;  -- SQL Server requires explicit DEALLOCATE

    -- Update sales order status based on result
    IF @v_errors = ''
    BEGIN
        UPDATE sales_orders SET status = 'fulfilled' WHERE so_id = @p_so_id;
        SET @p_msg = 'SUCCESS: SO #' + CAST(@p_so_id AS NVARCHAR) + ' fully fulfilled';
    END
    ELSE
    BEGIN
        UPDATE sales_orders SET status = 'partial' WHERE so_id = @p_so_id;
        SET @p_msg = 'PARTIAL: ' + @v_errors;
    END
END;
GO

-- Usage:
-- DECLARE @msg NVARCHAR(300);
-- EXEC ProcessSalesOrder @p_so_id = 3, @p_msg = @msg OUTPUT;
-- SELECT @msg AS result;

-- ??? TRIGGER ???????????????????????????????????????????????
-- SQL Server triggers fire once per statement (not per row).
-- Use the virtual INSERTED and DELETED tables to compare
-- old vs new values across all affected rows.

CREATE OR ALTER TRIGGER trg_reorder_alert
ON products_inv
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERTED = new row values, DELETED = old row values
    -- Insert a reorder log entry for every product that
    -- just crossed below its reorder threshold
    INSERT INTO reorder_log (product_id, stock_at_trigger, reorder_qty)
    SELECT
        i.product_id,
        i.stock_qty,
        i.reorder_level * 3
    FROM INSERTED i
    INNER JOIN DELETED d ON i.product_id = d.product_id
    WHERE i.stock_qty  <= i.reorder_level   -- now at/below threshold
      AND d.stock_qty  >  d.reorder_level;  -- was above threshold before
END;
GO

-- ??? VIEW ??????????????????????????????????????????????????

CREATE OR ALTER VIEW vw_stock_status AS
SELECT
    p.sku,
    p.name,
    cat.name        AS category,
    p.stock_qty,
    p.reorder_level,
    p.max_stock,
    -- SQL Server CASE expression (same syntax as MySQL)
    CASE
        WHEN p.stock_qty = 0                      THEN 'OUT OF STOCK'
        WHEN p.stock_qty <= p.reorder_level        THEN 'LOW STOCK'
        WHEN p.stock_qty >= p.max_stock * 0.9      THEN 'OVERSTOCKED'
        ELSE                                            'NORMAL'
    END AS stock_status,
    (p.stock_qty * p.cost_price)                  AS inventory_value
FROM products_inv p
INNER JOIN inv_categories cat ON p.cat_id = cat.cat_id;
GO

-- ??? INDEXES ???????????????????????????????????????????????
-- SQL Server index syntax is identical to MySQL

CREATE INDEX idx_prod_inv_cat    ON products_inv(cat_id);
CREATE INDEX idx_so_items_prod   ON so_items(product_id);
CREATE INDEX idx_po_items_prod   ON po_items(product_id);
CREATE INDEX idx_stock_mvt_prod  ON stock_movements(product_id);
GO

-- ??? CTE: ABC Inventory Analysis (Pareto 80/15/5) ??????????
-- SQL Server fully supports CTEs and window functions.
-- SUM() OVER (ORDER BY ...) for running total is identical.

WITH product_rev AS (
    -- Step 1: Total revenue earned per product
    SELECT
        p.product_id,
        p.sku,
        p.name,
        SUM(si.quantity * si.unit_price) AS revenue
    FROM products_inv p
    INNER JOIN so_items si ON p.product_id = si.product_id
    GROUP BY p.product_id, p.sku, p.name
),
grand AS (
    -- Step 2: Grand total revenue across all products
    SELECT SUM(revenue) AS total FROM product_rev
),
ranked AS (
    -- Step 3: Compute revenue %, cumulative revenue using window function
    SELECT
        pr.product_id,
        pr.sku,
        pr.name,
        pr.revenue,
        gr.total,
        ROUND(pr.revenue / gr.total * 100, 2) AS rev_pct,
        SUM(pr.revenue) OVER (ORDER BY pr.revenue DESC
                              ROWS BETWEEN UNBOUNDED PRECEDING
                              AND CURRENT ROW)    AS cum_rev
        -- ROWS BETWEEN ... is explicit in SQL Server for clarity
    FROM product_rev pr
    CROSS JOIN grand gr  -- SQL Server: CROSS JOIN is cleaner than comma join
)
SELECT
    sku,
    name,
    revenue,
    rev_pct,
    ROUND(cum_rev / total * 100, 2)                 AS cum_pct,
    CASE
        WHEN cum_rev / total <= 0.80 THEN 'A - High Value'
        WHEN cum_rev / total <= 0.95 THEN 'B - Medium Value'
        ELSE                              'C - Low Value'
    END                                             AS abc_class
FROM ranked
ORDER BY revenue DESC;
GO