-- ============================================================
-- Migration 005: Setup Storage for Menu and Offer Images
-- ============================================================

-- 1. Create the 'assets' bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('assets', 'assets', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Set up RLS Policies for the 'assets' bucket
-- (Note: storage.objects RLS is enabled by default in Supabase)

-- A. Public Access: Everyone can view images
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'assets');

-- B. Manager Access: Authenticated managers can upload, update, and delete
CREATE POLICY "Managers can upload assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'assets' AND
    (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'manager'))
);

CREATE POLICY "Managers can update assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'assets' AND
    (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'manager'))
);

CREATE POLICY "Managers can delete assets"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'assets' AND
    (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'manager'))
);
