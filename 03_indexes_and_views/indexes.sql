-- Phase 3a: Indexes
-- Without indexes, queries do a sequential scan (O(n)).
-- With a B-tree index, lookups are O(log n).
-- PRIMARY KEY and UNIQUE columns are indexed automatically.

CREATE INDEX idx_orders_user_id        ON orders(user_id);
CREATE INDEX idx_orders_created_at     ON orders(created_at);
CREATE INDEX idx_orders_status         ON orders(status);
CREATE INDEX idx_order_items_order_id  ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id     ON payments(order_id);
CREATE INDEX idx_products_category_id  ON products(category_id);
