-- Data Cleansing for tbl_transaction: Fix Date Format
SELECT      
   trx_id,
   product_id,
   STR_TO_DATE(LPAD(trx_date, 8, '0'), '%d%m%Y') AS trx_date,
   COALESCE(units, 0) AS units,
   'SYSTEM' AS insert_by,
   '2025-08-17 10:00:00' AS insert_date
FROM tbl_transaction
WHERE trx_id IS NOT NULL
AND STR_TO_DATE(LPAD(trx_date, 8, '0'), '%d%m%Y') = (
    SELECT MAX(STR_TO_DATE(LPAD(trx_date, 8, '0'), '%d%m%Y')) 
    FROM tbl_transaction
);


-- Create tbl_dwh_transaction Table
CREATE TABLE tbl_dwh_transaction (
    trx_id VARCHAR(50),                  
    product_id VARCHAR(50),              
    trx_date DATE,
    units INT,
    insert_by VARCHAR(50),
    insert_date DATETIME
);

INSERT INTO tbl_dwh_transaction(trx_id, product_id, trx_date, units, insert_by, insert_date)
SELECT
    trx_id,
    product_id,
    STR_TO_DATE(LPAD(trx_date, 8, '0'), '%d%m%Y') AS trx_date,
    COALESCE(units, 0) AS units,
    'SYSTEM' AS insert_by,
    NOW() AS insert_date
FROM tbl_transaction
WHERE trx_id IS NOT NULL
AND STR_TO_DATE(LPAD(trx_date, 8, '0'), '%d%m%Y') = (
    SELECT MAX(STR_TO_DATE(LPAD(trx_date, 8, '0'), '%d%m%Y'))
    FROM tbl_transaction
);



-- Data Cleansing for tbl_product: Fix Numeric Format
SELECT DISTINCT
	product_id,
	product_name,
	product_category,
	CAST(REPLACE(product_cost, 'IDR', '') AS FLOAT) AS product_cost,
	CAST(REPLACE(product_price, 'IDR', '') AS FLOAT) AS product_price,
	'SYSTEM' AS insert_by,
	'2025-08-17 10:00:00' AS insert_date
FROM tbl_product
WHERE product_id IS NOT NULL;


-- Create tbl_dwh_product Table
CREATE TABLE tbl_dwh_product (
    product_id VARCHAR(255),        
    product_name VARCHAR(255),
    product_category VARCHAR(100),
    product_cost DECIMAL(15, 0),    
    product_price DECIMAL(15, 0),   
    insert_by VARCHAR(50),
    insert_date DATETIME
);

INSERT INTO tbl_dwh_product (product_id, product_name, product_category, product_cost, product_price, insert_by, insert_date)
SELECT DISTINCT
    product_id,
    product_name,
    product_category,
    CAST(REPLACE(product_cost, 'IDR ', '') AS FLOAT) AS product_cost,
    CAST(REPLACE(product_price, 'IDR ', '') AS FLOAT) AS product_price,
    'SYSTEM' AS insert_by,
    NOW() AS insert_date
FROM tbl_product
WHERE product_id IS NOT NULL;



-- Data Cleansing for tbl_funnels: Fix Date Format
SELECT  
	STR_TO_DATE(LPAD(date, 8, '0'), '%d%m%Y') AS date,
	product_id,
	purchase,
	add_to_cart,
	click,
	view,
	'SYSTEM' AS insert_by,
    '2025-08-17 10:00:00' AS insert_date
FROM tbl_funnels
WHERE STR_TO_DATE(LPAD(date, 8, '0'), '%d%m%Y') = (
    SELECT MAX(STR_TO_DATE(LPAD(date, 8, '0'), '%d%m%Y')) 
    FROM tbl_funnels
);


-- Create tbl_dwh_funnels Table
CREATE TABLE tbl_dwh_funnels (
    `date` DATE,
    product_id VARCHAR(50),  
    purchase INT,
    add_to_cart INT,
    click INT,
    view INT,
    insert_by VARCHAR(50),
    insert_date DATETIME
);

INSERT INTO tbl_dwh_funnels (`date`, product_id, purchase, add_to_cart, click, view, insert_by, insert_date)
SELECT
    STR_TO_DATE(LPAD(`date`, 8, '0'), '%d%m%Y') AS `date`,
    product_id,
    purchase,
    add_to_cart,
    click,
    view,
    'SYSTEM' AS insert_by,
    NOW() AS insert_date
FROM tbl_funnels
WHERE STR_TO_DATE(LPAD(`date`, 8, '0'), '%d%m%Y') =
(SELECT MAX(STR_TO_DATE(LPAD(`date`, 8, '0'), '%d%m%Y')) FROM tbl_funnels);

-- Create Summary Table
CREATE TABLE f_summary_transaction (
    product_id VARCHAR(15),
    trx_date DATE,
    total_units INT,
    cost_each FLOAT,
    price_each FLOAT,
    total_price FLOAT,
    total_profit FLOAT,
    total_purchase INT,
    total_click INT,
    total_view INT,
    insert_by VARCHAR(50),
    insert_date DATETIME
);


-- Data Integration (JOIN DATA)
INSERT INTO f_summary_transaction (product_id, trx_date, total_units, cost_each, price_each, total_price, total_profit, total_purchase, total_click, total_view, insert_by, insert_date)
WITH transaction AS (
   SELECT
      product_id,
      trx_date,
      SUM(units) AS total_unit
   FROM tbl_dwh_transaction
   WHERE trx_date = (SELECT MAX(trx_date) FROM tbl_dwh_transaction)
   GROUP BY product_id, trx_date
),
product AS (
    SELECT DISTINCT
      product_id,
      product_cost,
      product_price
   FROM tbl_dwh_product
),
funnels AS (
    SELECT
      `date`,
      product_id,
      SUM(purchase) AS total_purchase,
      SUM(add_to_cart) AS total_add_to_cart,
      SUM(click) AS total_click,
      SUM(view) AS total_view
   FROM tbl_dwh_funnels
   WHERE `date` = (SELECT MAX(`date`) FROM tbl_dwh_funnels)
   GROUP BY `date`, product_id
)
SELECT 
      f.product_id,
      f.`date` AS trx_date,
      COALESCE(t.total_unit, 0) AS total_units,
      p.product_cost AS cost_each,
      p.product_price AS price_each,
      COALESCE(t.total_unit, 0) * p.product_price AS total_price,
      COALESCE(t.total_unit, 0) * (p.product_price - p.product_cost) AS total_profit,
      f.total_purchase,
      f.total_add_to_cart,
      f.total_click,
      f.total_view,
      'SYSTEM' AS insert_by,
      '2025-08-17 10:00:00' AS insert_date
FROM funnels AS f 
LEFT JOIN transaction AS t ON t.product_id = f.product_id AND t.trx_date = f.`date`
INNER JOIN product AS p ON f.product_id = p.product_id;




