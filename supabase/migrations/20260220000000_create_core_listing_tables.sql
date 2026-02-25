-- Core listing tables required before add_business_parishes and other migrations.
-- Safe to run on existing DB: CREATE TABLE IF NOT EXISTS.

-- 1. business_categories (referenced by businesses.category_id and subcategories.category_id)
CREATE TABLE IF NOT EXISTS public.business_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  icon text,
  sort_order integer NOT NULL DEFAULT 0
);

-- 2. subcategories (referenced by business_subcategories)
CREATE TABLE IF NOT EXISTS public.subcategories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category_id uuid NOT NULL REFERENCES public.business_categories(id) ON DELETE CASCADE
);

-- 3. businesses (referenced by business_parishes, business_subcategories, etc.)
CREATE TABLE IF NOT EXISTS public.businesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  category_id uuid NOT NULL REFERENCES public.business_categories(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  city text,
  parish text,
  state text,
  address text,
  phone text,
  website text,
  description text,
  tagline text,
  latitude double precision,
  longitude double precision,
  contact_form_template text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_businesses_category_id ON public.businesses(category_id);
CREATE INDEX IF NOT EXISTS idx_businesses_status ON public.businesses(status);
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
