-- ============================================================
-- Seed Data for Restaurant App
-- ============================================================

-- 1. Insert Categories
INSERT INTO categories (name, description, sort_order) VALUES
('Pizzas', 'Delicious stone-baked pizzas with fresh ingredients', 1),
('Burgers', 'Gourmet burgers served with crispy fries', 2),
('Drinks', 'Refreshing cold drinks and juices', 3),
('Desserts', 'Sweet treats to end your meal', 4);

-- 2. Insert Menu Items
-- Get category IDs
DO $$
DECLARE
    pizza_id UUID;
    burger_id UUID;
    drink_id UUID;
    dessert_id UUID;
BEGIN
    SELECT id INTO pizza_id FROM categories WHERE name = 'Pizzas';
    SELECT id INTO burger_id FROM categories WHERE name = 'Burgers';
    SELECT id INTO drink_id FROM categories WHERE name = 'Drinks';
    SELECT id INTO dessert_id FROM categories WHERE name = 'Desserts';

    -- Pizzas
    INSERT INTO menu_items (category_id, name, description, price, is_featured, sort_order, options) VALUES
    (pizza_id, 'Margherita', 'Classic tomato sauce, mozzarella, and fresh basil', 12.50, true, 1, '[
        {"name": "Size", "type": "single", "required": true, "choices": [{"name": "Medium", "price_addition": 0}, {"name": "Large", "price_addition": 4.00}]},
        {"name": "Extra Toppings", "type": "multiple", "required": false, "choices": [{"name": "Olives", "price_addition": 1.00}, {"name": "Mushrooms", "price_addition": 1.50}]}
    ]'),
    (pizza_id, 'Pepperoni Feast', 'Double pepperoni with extra mozzarella cheese', 14.99, true, 2, '[
        {"name": "Size", "type": "single", "required": true, "choices": [{"name": "Medium", "price_addition": 0}, {"name": "Large", "price_addition": 4.00}]}
    ]'),
    (pizza_id, 'Veggie Supreme', 'Mixed peppers, onions, mushrooms, and sweetcorn', 13.50, false, 3, '[]');

    -- Burgers
    INSERT INTO menu_items (category_id, name, description, price, is_featured, sort_order, options) VALUES
    (burger_id, 'Classic Cheeseburger', '100% Beef patty with cheddar, lettuce, and tomato', 11.00, true, 1, '[
        {"name": "Doneness", "type": "single", "required": true, "choices": [{"name": "Medium", "price_addition": 0}, {"name": "Well Done", "price_addition": 0}]}
    ]'),
    (burger_id, 'Bacon BBQ Burger', 'Beef patty with crispy bacon, BBQ sauce, and onion rings', 13.50, false, 2, '[]');

    -- Drinks
    INSERT INTO menu_items (category_id, name, description, price, sort_order) VALUES
    (drink_id, 'Coca-Cola', 'Chilled 330ml can', 2.50, 1),
    (drink_id, 'Fresh Orange Juice', 'Squeezed daily', 4.00, 2);

    -- Desserts
    INSERT INTO menu_items (category_id, name, description, price, sort_order) VALUES
    (dessert_id, 'Chocolate Brownie', 'Served warm with vanilla ice cream', 6.50, 1),
    (dessert_id, 'Cheesecake', 'New York style with berry compote', 7.00, 2);
END $$;

-- 3. Insert Tables
INSERT INTO tables (table_number, seats) VALUES
('1', 2),
('2', 4),
('3', 4),
('4', 6),
('5', 2);
