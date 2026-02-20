-- Migration 008: Sync prices with reference data
DO $$
DECLARE
    pizza_options JSONB;
BEGIN
    -- Updated pizza options with €4.50 addition for Medium size (to reach ~15 EUR average)
    pizza_options := '[
        {"name": "Size", "type": "single", "required": true, "choices": [{"name": "S", "price_addition": 0}, {"name": "M", "price_addition": 4.50}]},
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

    -- Update Pizza Prices
    UPDATE menu_items SET price = 10.50, options = pizza_options WHERE name = 'Margherita Mania';
    UPDATE menu_items SET price = 11.00, options = pizza_options WHERE name = 'Veggie Mania';
    UPDATE menu_items SET price = 12.50, options = pizza_options WHERE name = '4 Cheeses';
    UPDATE menu_items SET price = 12.00, options = pizza_options WHERE name = 'Chevre Miel';
    UPDATE menu_items SET price = 13.00, options = pizza_options WHERE name = 'BBQ Chicken';
    UPDATE menu_items SET price = 11.00, options = pizza_options WHERE name = 'Peperroni Mania';
    UPDATE menu_items SET price = 13.00, options = pizza_options WHERE name = 'Hannibal';
    UPDATE menu_items SET price = 12.50, options = pizza_options WHERE name = 'Hot Mania';
    UPDATE menu_items SET price = 13.50, options = pizza_options WHERE name = 'Scampi';

    -- Update Pasta Prices
    UPDATE menu_items SET price = 12.50 WHERE name = 'Bolognaise Maison';
    UPDATE menu_items SET price = 13.00 WHERE name = 'Carbonara';
    UPDATE menu_items SET price = 14.00 WHERE name = 'Chicken Mania';
    UPDATE menu_items SET price = 14.00 WHERE name = '4 Formaggi';

    -- Ensure all other pizzas have the updated options
    UPDATE menu_items SET options = pizza_options WHERE category_id = (SELECT id FROM categories WHERE name = 'Nos Pizzas') AND options IS NOT NULL AND name != 'Compose Ta Pizza';

END $$;
