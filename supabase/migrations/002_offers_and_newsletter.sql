-- ============================================================
-- Offers & Newsletter Schema
-- ============================================================

-- Newsletter Subscribers
CREATE TABLE newsletter_subscribers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Public can subscribe
CREATE POLICY "Anyone can subscribe to newsletter"
  ON newsletter_subscribers FOR INSERT
  WITH CHECK (true);

-- Only managers can read subscribers
CREATE POLICY "Managers can read subscribers"
  ON newsletter_subscribers FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'manager')
  );

-- Offers
CREATE TABLE offers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  contents TEXT NOT NULL,
  valid_until DATE NOT NULL,
  conditions TEXT,
  category TEXT NOT NULL CHECK (category IN ('delivery', 'takeaway')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE offers ENABLE ROW LEVEL SECURITY;

-- Public can read active offers
CREATE POLICY "Public can read active offers"
  ON offers FOR SELECT
  USING (is_active = true);

-- Managers can manage offers
CREATE POLICY "Managers can manage offers"
  ON offers FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'manager')
  );

-- ============================================================
-- Seed Data
-- ============================================================

INSERT INTO offers (name, price, contents, valid_until, conditions, category) VALUES
('Pizza Party Deal', 29.99, '2 Large Pizzas, 2 Sides, 1 Bottle of Soda (1.5L)', '2026-12-31', 'Valid for delivery only. Limited time offer.', 'delivery'),
('Family Feast Delivery', 45.00, '3 Medium Pizzas, 10 Chicken Wings, 2 Drinks', '2026-12-31', 'Cannot be combined with other offers.', 'delivery'),
('Quick Lunch Takeaway', 9.99, '1 Small Pizza + 1 Soft Drink', '2026-12-31', 'Valid for takeaway only between 11:00 and 15:00.', 'takeaway'),
('Double Treat Takeaway', 18.50, '2 Medium Pizzas + Large Garlic Bread', '2026-12-31', 'Valid every Tuesday and Thursday for pickup.', 'takeaway');
