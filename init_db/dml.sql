--INSERT INTO dim_customers (
--    first_name, last_name, age, email, country, postal_code,
--    pet_type, pet_name, pet_breed
--)
--SELECT DISTINCT
--    customer_first_name,
--    customer_last_name,
--    customer_age::INT,
--    customer_email,
--    customer_country,
--    customer_postal_code,
--    customer_pet_type,
--    customer_pet_name,
--    customer_pet_breed
--FROM sales_data;




INSERT INTO dim_sellers (
    first_name, last_name, email, country, postal_code
)
SELECT DISTINCT
    seller_first_name,
    seller_last_name,
    seller_email,
    seller_country,
    seller_postal_code
FROM sales_data;




--INSERT INTO dim_products (
--    product_id, name, category, price, weight, color, size, brand, material, description,
--    rating, reviews, release_date, expiry_date, pet_category
--)
--SELECT
--    sale_product_id,
--    product_name,
--    product_category,
--    product_price,
--    product_weight,
--    product_color,
--    product_size,
--    product_brand,
--    product_material,
--    product_description,
--    product_rating,
--    product_reviews,
--    product_release_date,
--    product_expiry_date,
--    pet_category
--FROM (
--    SELECT *,
--           ROW_NUMBER() OVER (PARTITION BY sale_product_id ORDER BY product_release_date DESC NULLS LAST) AS rn
--    FROM sales_data
--    WHERE sale_product_id IS NOT NULL
--) sub
--WHERE rn = 1
--ON CONFLICT (product_id) DO UPDATE SET
--    name = EXCLUDED.name,
--    category = EXCLUDED.category,
--    price = EXCLUDED.price,
--    weight = EXCLUDED.weight,
--    color = EXCLUDED.color,
--    size = EXCLUDED.size,
--    brand = EXCLUDED.brand,
--    material = EXCLUDED.material,
--    description = EXCLUDED.description,
--    rating = EXCLUDED.rating,
--    reviews = EXCLUDED.reviews,
--    release_date = EXCLUDED.release_date,
--    expiry_date = EXCLUDED.expiry_date,
--    pet_category = EXCLUDED.pet_category;



INSERT INTO dim_locations (location, city, state, country)
SELECT DISTINCT
    store_location,
    store_city,
    store_state,
    store_country
FROM sales_data
WHERE store_location IS NOT NULL;



INSERT INTO dim_stores (name, location_id, phone, email)
SELECT DISTINCT
    s.store_name,
    l.location_id,
    s.store_phone,
    s.store_email
FROM sales_data s
JOIN dim_locations l
  ON s.store_location = l.location
 AND s.store_city = l.city
 AND s.store_state = l.state
 AND s.store_country = l.country;


--CREATE UNIQUE INDEX idx_dim_stores_name_location ON dim_stores (name, location);
--
--INSERT INTO dim_stores (
--    name, location, city, state, country, phone, email
--)
--SELECT DISTINCT
--    store_name,
--    store_location,
--    store_city,
--    store_state,
--    store_country,
--    store_phone,
--    store_email
--FROM sales_data
--WHERE store_name IS NOT NULL AND store_location IS NOT NULL
--ON CONFLICT (name, location) DO NOTHING;




INSERT INTO dim_suppliers (
    name, contact, email, phone, address, city, country
)
SELECT DISTINCT
    supplier_name,
    supplier_contact,
    supplier_email,
    supplier_phone,
    supplier_address,
    supplier_city,
    supplier_country
FROM sales_data
ON CONFLICT DO NOTHING;




INSERT INTO dim_dates (
    date_id, day, month, year, quarter, day_of_week, is_weekend
)
SELECT DISTINCT
    sale_date AS date_id,
    EXTRACT(DAY FROM sale_date) AS day,
    EXTRACT(MONTH FROM sale_date) AS month,
    EXTRACT(YEAR FROM sale_date) AS year,
    EXTRACT(QUARTER FROM sale_date) AS quarter,
    EXTRACT(DOW FROM sale_date) + 1 AS day_of_week,
    EXTRACT(DOW FROM sale_date) IN (0, 6) AS is_weekend
FROM sales_data
WHERE sale_date IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;




INSERT INTO fact_sales (
    date_id, customer_id, seller_id, product_id,
    store_id, supplier_id, quantity, total_price
)
SELECT
    t.sale_date AS date_id,
    c.customer_id,
    s.seller_id,
    p.product_id,
    st.store_id,
    sp.supplier_id,
    t.sale_quantity::INT,
    t.sale_total_price::DECIMAL(10,2)
FROM sales_data t
JOIN dim_customers c ON t.customer_email = c.email
JOIN dim_sellers s ON t.seller_email = s.email
JOIN dim_products p ON t.product_name = p.name AND t.product_category = p.category
JOIN dim_stores st ON t.store_name = st.name AND t.store_location = st.location
JOIN dim_suppliers sp ON t.supplier_name = sp.name AND t.supplier_email = sp.email;




INSERT INTO dim_pets (pet_type, pet_name, pet_breed)
SELECT DISTINCT
    customer_pet_type,
    customer_pet_name,
    customer_pet_breed
FROM sales_data
WHERE customer_pet_type IS NOT NULL;



INSERT INTO dim_customers (first_name, last_name, age, email, country, postal_code, pet_id)
SELECT DISTINCT
    s.customer_first_name,
    s.customer_last_name,
    s.customer_age::INT,
    s.customer_email,
    s.customer_country,
    s.customer_postal_code,
    p.pet_id
FROM sales_data s
JOIN dim_pets p
  ON s.customer_pet_type = p.pet_type
 AND s.customer_pet_name = p.pet_name
 AND s.customer_pet_breed = p.pet_breed;





INSERT INTO dim_categories (category_name)
SELECT DISTINCT product_category FROM sales_data
WHERE product_category IS NOT NULL;



INSERT INTO dim_brands (brand_name)
SELECT DISTINCT product_brand FROM sales_data
WHERE product_brand IS NOT NULL;




INSERT INTO dim_materials (material_name)
SELECT DISTINCT product_material FROM sales_data
WHERE product_material IS NOT NULL;




INSERT INTO dim_colors (color_name)
SELECT DISTINCT product_color FROM sales_data
WHERE product_color IS NOT NULL;




INSERT INTO dim_sizes (size_name)
SELECT DISTINCT product_size FROM sales_data
WHERE product_size IS NOT NULL;




INSERT INTO dim_products (
    name, category_id, price, weight, color_id, size_id,
    brand_id, material_id, description, rating, reviews,
    release_date, expiry_date, pet_category
)
SELECT DISTINCT
    s.product_name,
    c.category_id,
    s.product_price,
    s.product_weight,
    co.color_id,
    sz.size_id,
    b.brand_id,
    m.material_id,
    s.product_description,
    s.product_rating,
    s.product_reviews,
    s.product_release_date,
    s.product_expiry_date,
    s.pet_category
FROM sales_data s
JOIN dim_categories c ON s.product_category = c.category_name
JOIN dim_colors co ON s.product_color = co.color_name
JOIN dim_sizes sz ON s.product_size = sz.size_name
JOIN dim_brands b ON s.product_brand = b.brand_name
JOIN dim_materials m ON s.product_material = m.material_name;



