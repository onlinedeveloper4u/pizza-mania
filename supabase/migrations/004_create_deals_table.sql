-- Create deals table
CREATE TABLE deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT, -- Used for listing contents
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    original_price DECIMAL(10,2),
    type TEXT NOT NULL CHECK (type IN ('delivery', 'takeaway', 'both')),
    validity TEXT,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    steps JSONB DEFAULT '[]'::jsonb, -- Configuration for the builder
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public can read active deals"
    ON deals FOR SELECT
    USING (is_active = true);

CREATE POLICY "Staff can manage deals"
    ON deals FOR ALL
    TO authenticated
    USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'admin'))
    );

-- Trigger for updated_at
CREATE TRIGGER deals_updated_at
    BEFORE UPDATE ON deals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Seed initial data (optional, based on hardcoded values)
INSERT INTO deals (title, type, price, original_price, description, validity, image_url, sort_order, steps) VALUES
('Family Feast', 'delivery', 29.90, 38.00, '2 Large Pizzas, 1 Garlic Bread, 1.5L Drink', 'Valid until Dec 2026', '/images/offer-family.jpg', 1, 
'[
    {"id": "pizza1", "title": "Choose First Pizza", "category": "Pizzas", "required": true},
    {"id": "pizza2", "title": "Choose Second Pizza", "category": "Pizzas", "required": true},
    {"id": "side", "title": "Choose a Side", "category": "Accompagnements", "required": true},
    {"id": "drink", "title": "Choose a Drink", "category": "Boissons", "required": true}
]'::jsonb),
('Couple Combo', 'delivery', 19.90, 24.50, '1 Large Pizza, 1 Side, 2 Drinks', 'Valid until Dec 2026', '/images/offer-couple.jpg', 2,
'[
    {"id": "pizza1", "title": "Choose Pizza", "category": "Pizzas", "required": true},
    {"id": "side", "title": "Choose Side", "category": "Accompagnements", "required": true},
    {"id": "drink1", "title": "Choose First Drink", "category": "Boissons", "required": true},
    {"id": "drink2", "title": "Choose Second Drink", "category": "Boissons", "required": true}
]'::jsonb),
('Lunch Special', 'takeaway', 9.90, 14.00, '1 Medium Pizza, 1 Drink', 'Mon-Fri, 11am - 3pm', '/images/offer-lunch.jpg', 3,
'[
    {"id": "pizza1", "title": "Choose Pizza", "category": "Pizzas", "required": true},
    {"id": "drink", "title": "Choose Drink", "category": "Boissons", "required": true}
]'::jsonb);
