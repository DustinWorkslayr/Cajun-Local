-- Fix set_businesses_slug: handle null/empty name so insert never fails.
CREATE OR REPLACE FUNCTION public.set_businesses_slug()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  base text;
BEGIN
  IF NEW.slug IS NULL OR trim(NEW.slug) = '' THEN
    base := public.slugify(coalesce(trim(NEW.name), ''));
    IF base IS NULL OR base = '' THEN
      base := 'business';
    END IF;
    NEW.slug := public.next_unique_slug(
      'public.businesses'::regclass,
      base,
      CASE WHEN TG_OP = 'UPDATE' THEN NEW.id::text ELSE NULL END
    );
  END IF;
  RETURN NEW;
END;
$$;
