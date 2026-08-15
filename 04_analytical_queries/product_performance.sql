-- Product revenue ranked within each category
-- PARTITION BY splits the window per category so each category
-- has its own rank starting at 1, independent of other categories.
-- The nested SUM(...) OVER (...) computes the category total
-- alongside each product row for the percentage calculation.

SELECT
    p.name                                          AS product_name,
    c.name                                          AS category_name,
    SUM(oi.quantity * oi.unit_price)                AS product_revenue,
    RANK() OVER (
        PARTITION BY p.category_id
        ORDER BY SUM(oi.quantity * oi.unit_price) DESC
    )                                               AS rank_in_category,
    SUM(SUM(oi.quantity * oi.unit_price)) OVER (
        PARTITION BY p.category_id
    )                                               AS category_total_revenue,
    ROUND(
        100.0 * SUM(oi.quantity * oi.unit_price) /
        SUM(SUM(oi.quantity * oi.unit_price)) OVER (PARTITION BY p.category_id),
    2)                                              AS pct_of_category
FROM products p
JOIN categories c   ON p.category_id = c.category_id
JOIN order_items oi ON p.product_id  = oi.product_id
GROUP BY p.product_id, p.name, p.category_id, c.name
ORDER BY c.name, rank_in_category;
