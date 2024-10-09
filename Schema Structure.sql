--- Schema Structure

--- Parent Table Creation :

-- Category 

CREATE TABLE category (
	category_id INT PRIMARY KEY,
	category_name VARCHAR(20)
);

-- Customers 

CREATE TABLE customers (
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(20),
	last_name VARCHAR(20),
	state VARCHAR(20),
	address VARCHAR(5) DEFAULT ('xxxx')
);

-- Sellers

CREATE TABLE sellers(
	seller_id INT PRIMARY KEY,
	seller_name VARCHAR(25),
	origin VARCHAR(10)
);

-- Updating datatype of Sellers table

ALTER TABLE sellers
	ALTER COLUMN origin TYPE VARCHAR(10);

--- Child Table Creation :

-- Product

CREATE TABLE products (
	product_id INT PRIMARY KEY,
	product_name VARCHAR(50),
	price FLOAT,
	cogs FLOAT,
	category_id INT, --FK
	CONSTRAINT products_fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

-- orders

CREATE TABLE orders(
	order_id INT PRIMARY KEY,
	order_date DATE,
	customer_id INT, --FK
	seller_id INT, --FK
	order_status VARCHAR(15),
	CONSTRAINT orders_fk_customers FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
	CONSTRAINT orders_fk_seller FOREIGN KEY(seller_id) REFERENCES sellers(seller_id)
);

-- order_items

CREATE TABLE order_items(
	order_item_id INT PRIMARY KEY,
	order_id INT, --FK
	product_id INT, --FK
	quantity INT,
	price_per_unit FLOAT,
	CONSTRAINT order_items_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id),
	CONSTRAINT order_items_fk_products FOREIGN KEY(product_id) REFERENCES products(product_id)	
);

-- payments

CREATE TABLE payments(
	payment_id INT PRIMARY KEY,
	order_id INT, --FK
	payment_date DATE,
	payment_status VARCHAR(20),
	CONSTRAINT payments_fk_orders FOREIGN KEY(order_id) REFERENCES orders(order_id)
);

-- shipping

CREATE TABLE shipping(
	shipping_id	INT PRIMARY KEY,
	order_id INT, -- FK
	shipping_date DATE,
	return_date DATE,
	shipping_providers VARCHAR(15),
	delivery_status VARCHAR(15),
	CONSTRAINT shipping_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- inventory
	
CREATE TABLE inventory(
	inventory_id INT,
	product_id INT, --FK
	stock INT,
	warehouse_id INT,
	last_stock_date DATE,
	CONSTRAINT inventory_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);

