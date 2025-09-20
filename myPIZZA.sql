-- Make sure you're in the right schema:
USE mypizzadb;

-- Use InnoDB + utf8mb4 everywhere
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Drop in case you're re-running during dev
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS address;
DROP TABLE IF EXISTS recipe;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS ingredient;
DROP TABLE IF EXISTS item;
DROP TABLE IF EXISTS rota;
DROP TABLE IF EXISTS shift;
DROP TABLE IF EXISTS staff;

SET FOREIGN_KEY_CHECKS = 1;

-- Core reference data
CREATE TABLE customers (
  cust_id INT NOT NULL AUTO_INCREMENT,
  cust_firstname VARCHAR(50) NOT NULL,
  cust_lastname  VARCHAR(50) NOT NULL,
  PRIMARY KEY (cust_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE address (
  address_id INT NOT NULL AUTO_INCREMENT,
  delivery_address1 VARCHAR(200) NOT NULL,
  delivery_address2 VARCHAR(200) NULL,
  delivery_city     VARCHAR(50)  NOT NULL,
  delivery_zipcode  VARCHAR(20)  NOT NULL,
  PRIMARY KEY (address_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE item (
  item_id   VARCHAR(10) NOT NULL,
  sku       VARCHAR(20) NOT NULL,
  item_name VARCHAR(50) NOT NULL,
  item_cat  VARCHAR(50) NOT NULL,
  item_size VARCHAR(20) NOT NULL,
  item_price DECIMAL(7,2) NOT NULL, -- allow >999.99 if needed
  PRIMARY KEY (item_id),
  UNIQUE KEY uq_item_sku (sku)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ingredient (
  ing_id    VARCHAR(10) NOT NULL,
  ing_name  VARCHAR(200) NOT NULL,   -- fixed: no hyphen
  ing_weight INT NOT NULL,
  ing_meas  VARCHAR(20) NOT NULL,
  ing_price DECIMAL(7,2) NOT NULL,
  PRIMARY KEY (ing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Inventory of ingredients
CREATE TABLE inventory (
  inv_id   INT NOT NULL AUTO_INCREMENT,
  ing_id   VARCHAR(10) NOT NULL,
  quantity INT NOT NULL,
  PRIMARY KEY (inv_id),
  KEY ix_inventory_ing (ing_id),
  CONSTRAINT fk_inventory_ing FOREIGN KEY (ing_id)
    REFERENCES ingredient (ing_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Recipe: which ingredients go into which item
CREATE TABLE recipe (
  recipe_id INT NOT NULL AUTO_INCREMENT,
  item_id   VARCHAR(10) NOT NULL,
  ing_id    VARCHAR(10) NOT NULL,
  quantity  INT NOT NULL,
  PRIMARY KEY (recipe_id),
  UNIQUE KEY uq_recipe_item_ing (item_id, ing_id),
  KEY ix_recipe_ing (ing_id),
  CONSTRAINT fk_recipe_item FOREIGN KEY (item_id)
    REFERENCES item (item_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_recipe_ing FOREIGN KEY (ing_id)
    REFERENCES ingredient (ing_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Orders + order items (junction table)
CREATE TABLE orders (
  row_id     INT NOT NULL AUTO_INCREMENT,
  order_id   VARCHAR(10) NOT NULL,
  created_at DATETIME NOT NULL,
  cust_id    INT NOT NULL,
  delivery   TINYINT(1) NOT NULL,  -- BOOLEAN alias; stored as 0/1
  address_id INT NOT NULL,
  PRIMARY KEY (row_id),
  UNIQUE KEY uq_orders_order_id (order_id),
  KEY ix_orders_cust (cust_id),
  KEY ix_orders_address (address_id),
  CONSTRAINT fk_orders_customer FOREIGN KEY (cust_id)
    REFERENCES customers (cust_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_orders_address FOREIGN KEY (address_id)
    REFERENCES address (address_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE order_items (
  row_id   INT NOT NULL AUTO_INCREMENT,
  order_id VARCHAR(10) NOT NULL,
  item_id  VARCHAR(10) NOT NULL,
  quantity INT NOT NULL,
  PRIMARY KEY (row_id),
  UNIQUE KEY uq_order_item (order_id, item_id),
  KEY ix_oi_item (item_id),
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id)
    REFERENCES orders (order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_oi_item FOREIGN KEY (item_id)
    REFERENCES item (item_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Staffing & rota
CREATE TABLE staff (
  staff_id   VARCHAR(20) NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name  VARCHAR(50) NOT NULL,
  position   VARCHAR(100) NOT NULL,
  hourly_rate DECIMAL(7,2) NOT NULL,
  PRIMARY KEY (staff_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE shift (
  shift_id   VARCHAR(20) NOT NULL,
  day_of_week VARCHAR(10) NOT NULL,
  start_time TIME NOT NULL,
  end_time   TIME NOT NULL,
  PRIMARY KEY (shift_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE rota (
  row_id  INT NOT NULL AUTO_INCREMENT,
  rota_id VARCHAR(20) NOT NULL,
  dt      DATETIME NOT NULL,
  shift_id VARCHAR(20) NOT NULL,
  staff_id VARCHAR(20) NOT NULL,
  PRIMARY KEY (row_id),
  UNIQUE KEY uq_rota (rota_id),
  KEY ix_rota_shift (shift_id),
  KEY ix_rota_staff (staff_id),
  CONSTRAINT fk_rota_shift FOREIGN KEY (shift_id)
    REFERENCES shift (shift_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_rota_staff FOREIGN KEY (staff_id)
    REFERENCES staff (staff_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

USE mypizzadb;

START TRANSACTION;

-- 1) Customers
INSERT INTO customers (cust_firstname, cust_lastname) VALUES
('John','Doe'),
('Jane','Smith');

-- 2) Addresses
INSERT INTO address (delivery_address1, delivery_address2, delivery_city, delivery_zipcode) VALUES
('123 Main St', NULL, 'Metropolis', '12345'),
('77 Broadway Ave', 'Apt 5B', 'Gotham', '10001');

-- 3) Staff
INSERT INTO staff (staff_id, first_name, last_name, position, hourly_rate) VALUES
('S001','Mario','Rossi','Cook',22.50),
('S002','Luigi','Bianchi','Cashier',18.00);

-- 4) Shifts
INSERT INTO shift (shift_id, day_of_week, start_time, end_time) VALUES
('SH1','Monday','10:00:00','18:00:00'),
('SH2','Saturday','16:00:00','23:00:00');

-- 5) Items (menu)
INSERT INTO item (item_id, sku, item_name, item_cat, item_size, item_price) VALUES
('PZ001','SKU-PZ-001','Margherita Pizza','Pizza','12in',12.99),
('PZ002','SKU-PZ-002','Pepperoni Pizza','Pizza','12in',14.49),
('DR001','SKU-DR-001','Cola Can','Drink','12oz',1.99);

-- 6) Ingredients
INSERT INTO ingredient (ing_id, ing_name, ing_weight, ing_meas, ing_price) VALUES
('ING001','Tomato Sauce',1000,'ml',4.50),
('ING002','Mozzarella',1000,'g',7.80),
('ING003','Pepperoni',1000,'g',9.20),
('ING004','Basil',100,'g',1.20),
('ING005','Dough Ball',10,'pcs',5.00);

-- 7) Inventory (ingredient stock)
INSERT INTO inventory (ing_id, quantity) VALUES
('ING001', 10),
('ING002', 8),
('ING003', 5),
('ING004', 3),
('ING005', 20);

-- 8) Recipes (which ingredients each item uses)
-- Margherita: dough, sauce, mozzarella, basil
INSERT INTO recipe (item_id, ing_id, quantity) VALUES
('PZ001','ING005',1),
('PZ001','ING001',150),
('PZ001','ING002',120),
('PZ001','ING004',5);

-- Pepperoni: dough, sauce, mozzarella, pepperoni
INSERT INTO recipe (item_id, ing_id, quantity) VALUES
('PZ002','ING005',1),
('PZ002','ING001',150),
('PZ002','ING002',120),
('PZ002','ING003',80);

-- 9) Rota (who works when)
INSERT INTO rota (rota_id, dt, shift_id, staff_id) VALUES
('R001','2025-09-20 10:00:00','SH1','S001'),
('R002','2025-09-20 16:00:00','SH2','S002');

-- 10) Orders (header)
INSERT INTO orders (order_id, created_at, cust_id, delivery, address_id) VALUES
('O1001','2025-09-20 11:15:00', 1, 1, 1),
('O1002','2025-09-20 18:30:00', 2, 0, 2);

-- 11) Order items (lines)
INSERT INTO order_items (order_id, item_id, quantity) VALUES
('O1001','PZ001',2),
('O1001','DR001',2),
('O1002','PZ002',1),
('O1002','PZ001',1);

COMMIT;

