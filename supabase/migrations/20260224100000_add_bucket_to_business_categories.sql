-- Add bucket to business_categories: required enum-like field to group categories
-- (hire, eat, shop, explore).

ALTER TABLE public.business_categories
  ADD COLUMN IF NOT EXISTS bucket text;
UPDATE public.business_categories
  SET bucket = 'explore'
  WHERE bucket IS NULL;
ALTER TABLE public.business_categories
  ALTER COLUMN bucket SET NOT NULL;
ALTER TABLE public.business_categories
  DROP CONSTRAINT IF EXISTS business_categories_bucket_check;
ALTER TABLE public.business_categories
  ADD CONSTRAINT business_categories_bucket_check
  CHECK (bucket IN ('hire', 'eat', 'shop', 'explore'));
COMMENT ON COLUMN public.business_categories.bucket IS 'Grouping bucket: hire | eat | shop | explore';
