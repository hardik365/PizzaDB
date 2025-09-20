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
