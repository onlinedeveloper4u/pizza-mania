-- ============================================================
-- Migration 003: Update Menu to full 'Pizza Mania' catalog
-- ============================================================

-- 1. Ensure unique constraint on category name for upsert support
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'categories_name_key') THEN
        ALTER TABLE categories ADD CONSTRAINT categories_name_key UNIQUE (name);
    END IF;
END $$;

-- 2. Cleanup Old Data (Delete orders first to avoid FK violations)
DELETE FROM orders;
DELETE FROM menu_items;
DELETE FROM categories WHERE name NOT IN ('Nos Pizzas', 'Nos Pâtes', 'Buckets', 'Accompagnements', 'Boissons', 'Boissons Chaudes', 'Desserts');

-- 3. Create or ensure Categories exist
INSERT INTO categories (name, description, sort_order) VALUES
('Nos Pizzas', 'Hand-crafted pizzas with premium ingredients', 1),
('Nos Pâtes', 'Authentic Italian pasta (Penne, Tagliatelle, or Spaghetti)', 2),
('Buckets', 'Crispy chicken buckets and portions', 3),
('Accompagnements', 'Sides and appetizers', 4),
('Boissons', 'Cold and refreshing beverages', 5),
('Boissons Chaudes', 'Professional espresso and hot drinks', 6),
('Desserts', 'Sweet treats and desserts', 7)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

-- 3. Insert New Menu Items
DO $$
DECLARE
    pizza_id UUID;
    pasta_id UUID;
    bucket_id UUID;
    side_id UUID;
    drink_id UUID;
    hot_drink_id UUID;
    dessert_id UUID;
    pizza_options JSONB;
    pasta_options JSONB;
BEGIN
    SELECT id INTO pizza_id FROM categories WHERE name = 'Nos Pizzas';
    SELECT id INTO pasta_id FROM categories WHERE name = 'Nos Pâtes';
    SELECT id INTO bucket_id FROM categories WHERE name = 'Buckets';
    SELECT id INTO side_id FROM categories WHERE name = 'Accompagnements';
    SELECT id INTO drink_id FROM categories WHERE name = 'Boissons';
    SELECT id INTO hot_drink_id FROM categories WHERE name = 'Boissons Chaudes';
    SELECT id INTO dessert_id FROM categories WHERE name = 'Desserts';

    -- Common Options
    pizza_options := '[
        {"name": "Size", "type": "single", "required": true, "choices": [{"name": "S", "price_addition": 0}, {"name": "M", "price_addition": 3.00}]},
        {"name": "Supplement Sauce", "type": "single", "required": false, "choices": [
            {"name": "Bbq swirl", "price_addition": 0.50},
            {"name": "Algérienne swirl", "price_addition": 0.50},
            {"name": "Ail", "price_addition": 0.50},
            {"name": "Samurai", "price_addition": 0.50},
            {"name": "Huile à l''ail maison", "price_addition": 0}
        ]},
        {"name": "Extra Ingredients", "type": "multiple", "required": false, "choices": [
            {"name": "Chevre", "price_addition": 1.50}, {"name": "Parmesan", "price_addition": 1.50}, {"name": "Gorgonzola", "price_addition": 1.50},
            {"name": "Emmental", "price_addition": 1.50}, {"name": "Poulet", "price_addition": 2.00}, {"name": "Boeuf", "price_addition": 2.00},
            {"name": "Bacon", "price_addition": 1.50}, {"name": "Ananas", "price_addition": 1.00}, {"name": "Capre", "price_addition": 1.00},
            {"name": "Jambon", "price_addition": 1.50}, {"name": "Merguez", "price_addition": 2.00}, {"name": "Kebab", "price_addition": 2.00},
            {"name": "Bolognaise", "price_addition": 2.00}, {"name": "Scampis", "price_addition": 3.00}, {"name": "Saumon", "price_addition": 3.00},
            {"name": "Fruit de Mer", "price_addition": 3.50}, {"name": "Oeuf", "price_addition": 1.00}, {"name": "Extra Mozzarella", "price_addition": 1.50}
        ]}
    ]';

    pasta_options := '[
        {"name": "Type", "type": "single", "required": true, "choices": [{"name": "Penne", "price_addition": 0}, {"name": "Tagliatelle", "price_addition": 0}, {"name": "Spaghetti", "price_addition": 0}]},
        {"name": "Gratinée au Four", "type": "single", "required": false, "choices": [{"name": "Yes", "price_addition": 2.00}]}
    ]';

    -- 1. Pizzas
    INSERT INTO menu_items (category_id, name, description, price, options, sort_order) VALUES
    (pizza_id, 'Margherita Mania', 'Sauce tomate, mozzarella, olives noires, origan', 12.00, pizza_options, 1),
    (pizza_id, 'Veggie Mania', 'Sauce tomate, mozzarella, olives, oignons, poivrons, tomate, champignons, artichauts, origan', 14.50, pizza_options, 2),
    (pizza_id, '4 Cheeses', 'Sauce tomate, mozzarella, chèvre, gorgonzola, emmental', 15.00, pizza_options, 3),
    (pizza_id, 'Funghi', 'Sauce tomate, mozzarella, champignons, origan', 13.00, pizza_options, 4),
    (pizza_id, 'Creamy 4 Cheeses', 'Sauce crème, mozzarella, emmental, chèvre, gorgonzola, origan', 15.50, pizza_options, 5),
    (pizza_id, 'Chevre Miel', 'Sauce tomate, chèvre, miel', 13.50, pizza_options, 6),
    (pizza_id, 'Savoyarde', 'Sauce crème, pommes de terre, reblochon, bacon, origan', 15.50, pizza_options, 7),
    (pizza_id, 'Toscane', 'Sauce tomate, mozzarella jambon', 13.50, pizza_options, 8),
    (pizza_id, '4 Saisons', 'Sauce tomate, mozzarella, jambon, champignons, artichauts, olives', 15.00, pizza_options, 9),
    (pizza_id, 'Peperroni Mania', 'Sauce tomate, pepperoni, mozzarella', 14.00, pizza_options, 10),
    (pizza_id, 'Chicken Kebab', 'Sauce tomate, kebab, oignons, poivrons, swirl samouraï', 15.50, pizza_options, 11),
    (pizza_id, 'Hannibal', 'Sauce barbecue, mozzarella, poulet, merguez, boeuf', 16.00, pizza_options, 12),
    (pizza_id, 'Hot Mania', 'Sauce tomate, mozzarella, merguez, pepperoni, champignons, piment swirl algérienne', 15.50, pizza_options, 13),
    (pizza_id, 'Creamy Mania', 'Sauce crème, champignons, oignons, pepperoni, merguez, poulet, ail', 16.50, pizza_options, 14),
    (pizza_id, 'BBQ Chicken', 'Sauce tomate, poulet, oignons, poivrons, swirl BBQ', 15.00, pizza_options, 15),
    (pizza_id, 'BBQ Grill', 'Sauce BBQ, mozzarella, bacon, boeuf, oignons, swirl BBQ', 15.50, pizza_options, 16),
    (pizza_id, 'Scampi', 'Sauce tomate, scampi, huile à l''ail maison', 16.50, pizza_options, 17),
    (pizza_id, 'Saumon', 'Sauce tomate saumon oignon sauce crème', 16.50, pizza_options, 18),
    (pizza_id, 'Tonno', 'Sauce tomate, thon, oignons, olives noires', 15.00, pizza_options, 19),
    (pizza_id, 'Forestiere', 'Sauce tomate, mozzarella, jambon, champignons, bacon', 14.50, pizza_options, 20),
    (pizza_id, 'Compose Ta Pizza', 'Créez votre propre pizza selon vos envies', 12.00, '[
        {"name": "Size", "type": "single", "required": true, "choices": [{"name": "La solo", "price_addition": 0}, {"name": "La médium", "price_addition": 3.00}]},
        {"name": "Base de pizzas", "type": "single", "required": true, "choices": [
            {"name": "Sauce tomate", "price_addition": 0},
            {"name": "Sauce crème", "price_addition": 0},
            {"name": "Sauce BBQ", "price_addition": 0},
            {"name": "Sans sauce", "price_addition": 0}
        ]},
        {"name": "Supplement Sauce", "type": "single", "required": false, "choices": [
            {"name": "Bbq swirl", "price_addition": 0.50},
            {"name": "Algérienne swirl", "price_addition": 0.50},
            {"name": "Ail", "price_addition": 0.50},
            {"name": "Samurai", "price_addition": 0.50},
            {"name": "Huile à l''ail maison", "price_addition": 0}
        ]},
        {"name": "Extra Ingredients", "type": "multiple", "required": false, "choices": [
            {"name": "Chevre", "price_addition": 1.50}, {"name": "Parmesan", "price_addition": 1.50}, {"name": "Gorgonzola", "price_addition": 1.50},
            {"name": "Emmental", "price_addition": 1.50}, {"name": "Poulet", "price_addition": 2.00}, {"name": "Boeuf", "price_addition": 2.00},
            {"name": "Bacon", "price_addition": 1.50}, {"name": "Ananas", "price_addition": 1.00}, {"name": "Capre", "price_addition": 1.00},
            {"name": "Jambon", "price_addition": 1.50}, {"name": "Merguez", "price_addition": 2.00}, {"name": "Kebab", "price_addition": 2.00}
        ]}
    ]', 21);

    -- 2. Pâtes
    INSERT INTO menu_items (category_id, name, description, price, options, sort_order) VALUES
    (pasta_id, 'Bolognaise Maison', 'Viande hachée, sauce tomates', 12.50, pasta_options, 1),
    (pasta_id, 'Diavola Mania', 'Viande hachée, sauce tomate, piments forts', 13.50, pasta_options, 2),
    (pasta_id, 'Provencale', 'Jambon, sauce crème, herbes aromatiques', 13.00, pasta_options, 3),
    (pasta_id, 'Carbonara', 'Lardons fumés, sauce crème, herbes', 13.50, pasta_options, 4),
    (pasta_id, 'Chicken Mania', 'Émincé de poulet rôti, sauce crème tomate, champignons, épices maison', 14.50, pasta_options, 5),
    (pasta_id, '4 Formaggi', 'Sauce crème fraîche, mozzarella, gorgonzola, chèvre, emmental', 14.50, pasta_options, 6),
    (pasta_id, 'Scampi', 'Scampis, sauce crème rose, muscade', 16.00, pasta_options, 7),
    (pasta_id, 'Saumon', 'Saumon fumé, sauce crème rose, citron', 16.50, pasta_options, 8);

    -- 3. Buckets
    INSERT INTO menu_items (category_id, name, description, price, sort_order) VALUES
    (bucket_id, 'Small Bucket', '8 tenders + 8 nuggets + sauce', 16.00, 1),
    (bucket_id, 'Accompagnement / Wings', 'Wings portions de 6 + sauce au choix', 8.50, 2),
    (bucket_id, 'Nuggets (8 portions)', '8 nuggets + sauce au choix', 8.00, 3),
    (bucket_id, 'Mix Buckets', '6 tenders + 6 wings + 8 nuggets + sauce', 19.50, 4),
    (bucket_id, 'Tenders (6 portions)', '6 tenders + sauce au choix', 9.50, 5),
    (bucket_id, 'Nuggets (12 portions)', '12 nuggets + sauce au choix', 11.50, 6);

    -- 4. Accompagnements
    INSERT INTO menu_items (category_id, name, description, price, sort_order) VALUES
    (side_id, 'Cheesy Bread (ail)', '6 lamelle de pain à l''ail', 4.50, 1),
    (side_id, 'Cheesy Bread Bacon', 'Cheesy bread with crispy bacon', 5.50, 2),
    (side_id, 'Supreme Cheesy Bread', 'Triple cheese blend bread', 6.00, 3);

    -- 5. Boissons
    INSERT INTO menu_items (category_id, name, description, price, options, sort_order) VALUES
    (drink_id, 'Soda 33 CL', 'Sélection de boissons rafraîchissantes', 2.00, '[
        {"name": "Saveur", "type": "single", "required": true, "choices": [
            {"name": "COCA", "price_addition": 0},
            {"name": "COCA ZÉRO", "price_addition": 0},
            {"name": "COCA CHERRY", "price_addition": 0},
            {"name": "FANTA", "price_addition": 0},
            {"name": "LIPTON ICE", "price_addition": 0},
            {"name": "TEA / PETILLANTE", "price_addition": 0},
            {"name": "TROPICO", "price_addition": 0}
        ]}
    ]', 1),
    (drink_id, 'Soda 50 CL', 'Sélection de boissons rafraîchissantes', 3.00, '[
        {"name": "Saveur", "type": "single", "required": true, "choices": [
            {"name": "FUZE TEA HIBISCUS", "price_addition": 0},
            {"name": "CHAUDE FONTAINE / PETILLANTE", "price_addition": 0}
        ]}
    ]', 2),
    (drink_id, 'Soda 1,5L', 'Sélection de boissons format familial', 4.50, '[
        {"name": "Saveur", "type": "single", "required": true, "choices": [
            {"name": "COCA", "price_addition": 0},
            {"name": "FANTA", "price_addition": 0},
            {"name": "SPRITE", "price_addition": 0},
            {"name": "COCA ZÉRO", "price_addition": 0}
        ]}
    ]', 3);

    -- 6. Boissons Chaudes
    INSERT INTO menu_items (category_id, name, description, price, sort_order) VALUES
    (hot_drink_id, 'Expresso', 'Rich Italian espresso', 2.50, 1),
    (hot_drink_id, 'Cappuccino', 'Classic cappuccino', 3.50, 2),
    (hot_drink_id, 'Café Latte Macchiato', 'Layered coffee with milk', 4.00, 3);


    -- 7. Desserts
    INSERT INTO menu_items (category_id, name, description, price, sort_order) VALUES
    (dessert_id, 'Moelleux au Chocolat', 'Warm chocolate cake', 6.00, 1),
    (dessert_id, 'Calzone Nutella', 'Sweet pizza fold with Nutella', 8.50, 2),
    (dessert_id, 'Alfiero Assortiment', 'Special dessert assortment', 7.50, 3);

END $$;
