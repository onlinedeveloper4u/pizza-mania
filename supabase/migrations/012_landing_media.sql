-- ============================================================
-- Migration 012: Create landing_media table for website media gallery
-- ============================================================

CREATE TABLE IF NOT EXISTS public.landing_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL CHECK (category IN ('craft', 'ambiance')),
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    url TEXT NOT NULL,
    title TEXT DEFAULT '',
    caption TEXT DEFAULT '',
    file_name TEXT NOT NULL,
    file_size INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add title column if table already existed without it
ALTER TABLE public.landing_media ADD COLUMN IF NOT EXISTS title TEXT DEFAULT '';

-- Enable RLS
ALTER TABLE public.landing_media ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (idempotent)
DROP POLICY IF EXISTS "Anyone can view landing media" ON public.landing_media;
DROP POLICY IF EXISTS "Managers can insert landing media" ON public.landing_media;
DROP POLICY IF EXISTS "Managers can update landing media" ON public.landing_media;
DROP POLICY IF EXISTS "Managers can delete landing media" ON public.landing_media;

-- Public read access (needed for the landing page later)
CREATE POLICY "Anyone can view landing media"
ON public.landing_media FOR SELECT
USING (true);

-- Managers can insert
CREATE POLICY "Managers can insert landing media"
ON public.landing_media FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'manager')
);

-- Managers can update (captions, titles, etc.)
CREATE POLICY "Managers can update landing media"
ON public.landing_media FOR UPDATE
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'manager')
);

-- Managers can delete
CREATE POLICY "Managers can delete landing media"
ON public.landing_media FOR DELETE
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'manager')
);
