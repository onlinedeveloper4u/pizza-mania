-- Migration: Making menu_item_id nullable and adding deal_id
-- This allows orders to contain "Deals" which are not standard menu items.

ALTER TABLE order_items ALTER COLUMN menu_item_id DROP NOT NULL;
ALTER TABLE order_items ADD COLUMN IF NOT EXISTS deal_id UUID REFERENCES deals(id);

COMMENT ON COLUMN order_items.menu_item_id IS 'Reference to menu_items (null if it is a deal)';
COMMENT ON COLUMN order_items.deal_id IS 'Reference to deals (if applicable)';
