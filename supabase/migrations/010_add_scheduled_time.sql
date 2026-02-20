-- Add scheduled_time column to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMPTZ;

-- Add a comment for clarity
COMMENT ON COLUMN orders.scheduled_time IS 'The user-selected time for delivery or pickup (scheduled order)';
