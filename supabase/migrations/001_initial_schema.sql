-- ============================================================
-- Restaurant App Database Schema
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. Profiles (Manager / Chef)
-- ============================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('manager', 'chef')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read their own profile
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Service role can do everything (used by admin client)

-- ============================================================
-- 2. Categories
-- ============================================================
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Everyone can read active categories
CREATE POLICY "Public can read active categories"
  ON categories FOR SELECT
  USING (is_active = true);

-- Authenticated managers can manage categories
CREATE POLICY "Managers can manage categories"
  ON categories FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'manager')
  );

-- ============================================================
-- 3. Menu Items
-- ============================================================
CREATE TABLE menu_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  sort_order INT DEFAULT 0,
  options JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;

-- Everyone can read available menu items
CREATE POLICY "Public can read available menu items"
  ON menu_items FOR SELECT
  USING (is_available = true);

-- Managers can manage menu items
CREATE POLICY "Managers can manage menu items"
  ON menu_items FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'manager')
  );

-- ============================================================
-- 4. Tables
-- ============================================================
CREATE TABLE tables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_number TEXT NOT NULL UNIQUE,
  seats INT DEFAULT 4,
  is_active BOOLEAN DEFAULT true,
  qr_code_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tables ENABLE ROW LEVEL SECURITY;

-- Public can read active tables (for QR validation)
CREATE POLICY "Public can read active tables"
  ON tables FOR SELECT
  USING (is_active = true);

-- Managers can manage tables
CREATE POLICY "Managers can manage tables"
  ON tables FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'manager')
  );

-- ============================================================
-- 5. Restaurant Settings
-- ============================================================
CREATE TABLE restaurant_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  restaurant_name TEXT NOT NULL DEFAULT 'Flavor Hub',
  address TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  operating_hours JSONB DEFAULT '{
    "monday": {"open": "11:00", "close": "22:00"},
    "tuesday": {"open": "11:00", "close": "22:00"},
    "wednesday": {"open": "11:00", "close": "22:00"},
    "thursday": {"open": "11:00", "close": "22:00"},
    "friday": {"open": "11:00", "close": "23:00"},
    "saturday": {"open": "11:00", "close": "23:00"},
    "sunday": {"open": "12:00", "close": "21:00"}
  }'::jsonb,
  delivery_fee DECIMAL(10,2) DEFAULT 3.99,
  avg_prep_minutes INT DEFAULT 30,
  accepting_orders BOOLEAN DEFAULT true,
  currency TEXT DEFAULT 'EUR'
);

ALTER TABLE restaurant_settings ENABLE ROW LEVEL SECURITY;

-- Everyone can read settings
CREATE POLICY "Public can read settings"
  ON restaurant_settings FOR SELECT
  USING (true);

-- Managers can update settings
CREATE POLICY "Managers can update settings"
  ON restaurant_settings FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'manager')
  );

-- Insert default settings row
INSERT INTO restaurant_settings (restaurant_name) VALUES ('Flavor Hub');

-- ============================================================
-- 6. Orders
-- ============================================================
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tracking_token TEXT NOT NULL UNIQUE,
  order_type TEXT NOT NULL CHECK (order_type IN ('delivery', 'pickup', 'dine_in')),
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN (
    'new', 'confirmed', 'preparing', 'ready',
    'out_for_delivery', 'delivered', 'picked_up', 'served', 'cancelled'
  )),
  customer_name TEXT NOT NULL DEFAULT '',
  customer_phone TEXT NOT NULL DEFAULT '',
  customer_email TEXT,
  delivery_address TEXT,
  table_id UUID REFERENCES tables(id),
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'counter' CHECK (payment_method IN ('online', 'counter')),
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
  stripe_session_id TEXT,
  special_instructions TEXT,
  estimated_minutes INT,
  confirmed_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Public can insert orders (anyone can place an order)
CREATE POLICY "Public can create orders"
  ON orders FOR INSERT
  WITH CHECK (true);

-- Public can read their own order via tracking token
CREATE POLICY "Public can read order by tracking token"
  ON orders FOR SELECT
  USING (true);

-- Authenticated staff can manage orders
CREATE POLICY "Staff can update orders"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'chef'))
  );

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- ============================================================
-- 7. Order Items
-- ============================================================
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES menu_items(id),
  item_name TEXT NOT NULL,
  item_price DECIMAL(10,2) NOT NULL,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  selected_options JSONB DEFAULT '{}'::jsonb,
  notes TEXT
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Public can insert order items
CREATE POLICY "Public can create order items"
  ON order_items FOR INSERT
  WITH CHECK (true);

-- Public can read order items
CREATE POLICY "Public can read order items"
  ON order_items FOR SELECT
  USING (true);

-- ============================================================
-- 8. Order Status History
-- ============================================================
CREATE TABLE order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  changed_by UUID REFERENCES profiles(id),
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;

-- Authenticated staff can read/write history
CREATE POLICY "Staff can manage status history"
  ON order_status_history FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('manager', 'chef'))
  );

-- Public can read (for tracking page timeline)
CREATE POLICY "Public can read status history"
  ON order_status_history FOR SELECT
  USING (true);

-- Public can insert (for initial order creation via service role)
CREATE POLICY "Public can insert status history"
  ON order_status_history FOR INSERT
  WITH CHECK (true);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_orders_tracking_token ON orders(tracking_token);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_table_id ON orders(table_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_menu_items_category_id ON menu_items(category_id);
CREATE INDEX idx_categories_sort_order ON categories(sort_order);
CREATE INDEX idx_menu_items_sort_order ON menu_items(sort_order);

-- ============================================================
-- Updated_at trigger for orders
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
