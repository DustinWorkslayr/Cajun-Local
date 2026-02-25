-- Add logo_url and banner_url to businesses for listing logo and dedicated banner image.
-- Required for admin/manager logo and banner upload; without this migration you get
-- "could not find logo_url or banner_url columns" when uploading.
-- logo_url: business logo (e.g. square avatar).
-- banner_url: dedicated listing banner/cover image (hero image when set).

ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS banner_url text;
COMMENT ON COLUMN public.businesses.logo_url IS 'Public URL of business logo (e.g. in business-images bucket).';
COMMENT ON COLUMN public.businesses.banner_url IS 'Public URL of listing banner/cover image (hero).';
