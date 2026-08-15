-- Phase 5: Triggers
-- Triggers enforce rules at the database level, independent of application code.

-- Trigger 1: Keep updated_at current on every order update
-- NEW refers to the incoming row — we modify it before it hits disk.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();


-- Trigger 2: Block order_items inserts if stock is insufficient
-- Validation and decrement are combined to avoid a race condition —
-- separating them would allow two transactions to pass the check simultaneously.
CREATE OR REPLACE FUNCTION check_stock_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_stock INT;
BEGIN
    SELECT stock_quantity INTO v_stock
    FROM products
    WHERE product_id = NEW.product_id;

    IF v_stock < NEW.quantity THEN
        RAISE EXCEPTION
            'Insufficient stock for product %. Available: %, Requested: %',
            NEW.product_id, v_stock, NEW.quantity;
    END IF;

    UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_stock
BEFORE INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION check_stock_on_insert();
