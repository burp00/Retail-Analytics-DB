-- Phase 2: Seed categories
-- Parent categories have NULL parent_category_id (top-level)

INSERT INTO categories (category_id, name, parent_category_id) VALUES
(1,  'Electronics',        NULL),
(2,  'Phones',             1),
(3,  'Laptops',            1),
(4,  'Audio',              1),
(5,  'Clothing',           NULL),
(6,  'Men''s',             5),
(7,  'Women''s',           5),
(8,  'Footwear',           5),
(9,  'Home & Kitchen',     NULL),
(10, 'Cookware',           9),
(11, 'Furniture',          9),
(12, 'Sports & Outdoors',  NULL),
(13, 'Fitness',            12),
(14, 'Camping',            12);
