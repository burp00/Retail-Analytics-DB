-- Phase 3b: Views
-- Saved queries that encapsulate complex joins so dashboards
-- don't repeat logic. Views rerun on every call — use a
-- materialized view if performance becomes an issue.

-- Total revenue and item count per order
CREATE VIEW v_order_revenue AS
SELECT
    o.order_id,
    o.user_id,
    o.status,
    o.created_at,
    SUM(oi.quantity * oi.unit_price) AS total_amount,
    COUNT(oi.order_item_id)          AS item_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.user_id, o.status, o.created_at;


-- Units sold, revenue, and order count per product
CREATE VIEW v_product_sales AS
SELECT
    p.product_id,
    p.name,
    c.name                           AS category_name,
    SUM(oi.quantity)                 AS total_units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    COUNT(DISTINCT oi.order_id)      AS num_orders
FROM products p
JOIN categories c   ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id  = oi.product_id
GROUP BY p.product_id, p.name, c.name;


-- Customer lifetime value with average LTV by country via window function
CREATE VIEW v_user_ltv AS
SELECT
    u.user_id,
    u.email,
    u.country,
    u.created_at                         AS member_since,
    COUNT(DISTINCT o.order_id)           AS total_orders,
    SUM(oi.quantity * oi.unit_price)     AS lifetime_value,
    AVG(SUM(oi.quantity * oi.unit_price))
        OVER (PARTITION BY u.country)    AS avg_ltv_by_country
FROM users u
JOIN orders o       ON u.user_id  = o.user_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('cancelled')
GROUP BY u.user_id, u.email, u.country, u.created_at;
