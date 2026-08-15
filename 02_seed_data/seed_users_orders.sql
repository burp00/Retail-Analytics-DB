-- Phase 2: Seed users, orders, order_items, payments
-- PL/pgSQL block generates ~500 users and ~2,500 orders programmatically.
-- RETURNING ... INTO captures generated UUIDs to link dependent inserts.
-- Payment rows are only created for confirmed/shipped/delivered orders
-- so retention and funnel queries reflect realistic business data.

DO $$
DECLARE
    v_user_id    UUID;
    v_order_id   UUID;
    v_product_id UUID;
    v_status     VARCHAR(20);
    v_country    CHAR(2);
    v_num_orders INT;
    v_num_items  INT;
    v_quantity   INT;
    v_price      NUMERIC(10,2);
    countries    CHAR(2)[]  := ARRAY['US','CA','GB','DE','FR','AU','JP','BR','IN','MX'];
    statuses     VARCHAR[]  := ARRAY['pending','confirmed','shipped','delivered','cancelled'];
    pay_methods  VARCHAR[]  := ARRAY['credit_card','debit_card','paypal','bank_transfer'];
    i            INT;
    j            INT;
    k            INT;
BEGIN

    FOR i IN 1..500 LOOP

        v_country := countries[1 + floor(random() * 10)::INT];

        INSERT INTO users (email, full_name, country, is_active, created_at)
        VALUES (
            'user' || i || '@example.com',
            'User ' || i,
            v_country,
            (random() > 0.1),
            NOW() - (random() * INTERVAL '2 years')
        )
        RETURNING user_id INTO v_user_id;

        v_num_orders := 1 + floor(random() * 10)::INT;

        FOR j IN 1..v_num_orders LOOP

            v_status := statuses[1 + floor(random() * 5)::INT];

            INSERT INTO orders (user_id, status, created_at, updated_at)
            VALUES (
                v_user_id,
                v_status,
                NOW() - (random() * INTERVAL '2 years'),
                NOW() - (random() * INTERVAL '1 month')
            )
            RETURNING order_id INTO v_order_id;

            v_num_items := 1 + floor(random() * 5)::INT;

            FOR k IN 1..v_num_items LOOP

                SELECT product_id, price
                INTO v_product_id, v_price
                FROM products
                ORDER BY random()
                LIMIT 1;

                v_quantity := 1 + floor(random() * 4)::INT;

                INSERT INTO order_items (order_id, product_id, quantity, unit_price)
                VALUES (v_order_id, v_product_id, v_quantity, v_price);

            END LOOP;

            IF v_status IN ('confirmed', 'shipped', 'delivered') THEN
                INSERT INTO payments (order_id, amount, method, status, paid_at)
                VALUES (
                    v_order_id,
                    (SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = v_order_id),
                    pay_methods[1 + floor(random() * 4)::INT],
                    'completed',
                    NOW() - (random() * INTERVAL '2 years')
                );

            ELSIF v_status = 'cancelled' AND random() > 0.5 THEN
                INSERT INTO payments (order_id, amount, method, status, paid_at)
                VALUES (
                    v_order_id,
                    (SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = v_order_id),
                    pay_methods[1 + floor(random() * 4)::INT],
                    'refunded',
                    NOW() - (random() * INTERVAL '2 years')
                );
            END IF;

        END LOOP;
    END LOOP;

END $$;
