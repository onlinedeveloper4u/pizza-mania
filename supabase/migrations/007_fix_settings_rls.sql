-- Add logo_url to restaurant_settings
ALTER TABLE restaurant_settings ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- Drop existing restrictive update policy
DROP POLICY IF EXISTS "Managers can update settings" ON restaurant_settings;

-- Create more comprehensive policy for managers (allowing UPSERT which needs INSERT and UPDATE)
CREATE POLICY "Managers can manage settings"
  ON restaurant_settings FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'manager')
  );
