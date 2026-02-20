-- Add logo_url to restaurant_settings
ALTER TABLE restaurant_settings ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- Update existing settings with default logo if not set
UPDATE restaurant_settings SET logo_url = '/logo.png' WHERE logo_url IS NULL;
