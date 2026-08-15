-- Phase 1: Schema — six tables in dependency order
-- categories > users > products > orders > order_items > payments

CREATE TABLE categories (
    category_id        SERIAL PRIMARY KEY,
    name               VARCHAR(100) NOT NULL,
    parent_category_id INT REFERENCES categories(category_id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- UUID so order counts are never exposed publicly
CREATE TABLE users (
    user_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email      VARCHAR(255) NOT NULL UNIQUE,
    full_name  VARCHAR(150) NOT NULL,
    country    CHAR(2)      NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- NUMERIC(10,2) for price — never FLOAT (binary rounding errors)
CREATE TABLE products (
    product_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id    INT NOT NULL REFERENCES categories(category_id) ON DELETE RESTRICT,
    name           VARCHAR(255) NOT NULL,
    price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- updated_at is kept current by a trigger (see 05_triggers/)
CREATE TABLE orders (
    order_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    status     VARCHAR(20) NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Junction table: one order can contain many products
-- unit_price stored here to preserve the price at time of purchase
CREATE TABLE order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id      UUID NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    UUID NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- UNIQUE on order_id enforces the one-to-one relationship with orders
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id   UUID NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE RESTRICT,
    amount     NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    method     VARCHAR(20) NOT NULL
                   CHECK (method IN ('credit_card','debit_card','paypal','bank_transfer')),
    status     VARCHAR(20) NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','completed','failed','refunded')),
    paid_at    TIMESTAMPTZ
);
