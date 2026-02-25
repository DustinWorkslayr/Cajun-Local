-- Add slug column to category, subcategory, businesses, parish, and ensure blog_posts slug is auto-generated from title.
-- Slugs: auto-generated from title/name; unique except we disambiguate with -1, -2 for duplicates (businesses: same).
-- Subcategory slug includes category: e.g. "restaurants-cajun".

-- 1. Slugify helper: lowercase, non-alphanumeric to hyphen, collapse hyphens, trim.
CREATE OR REPLACE FUNCTION public.slugify(value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT lower(
    trim(both '-' from
      regexp_replace(
        regexp_replace(
          regexp_replace(coalesce(value, ''), '[^a-zA-Z0-9\s-]', '', 'g'),
          '\s+', '-', 'g'
        ),
        '-+', '-', 'g'
      )
    )
  );
$$;
-- 2. Return next available slug for a table (base, or base-1, base-2, ...).
CREATE OR REPLACE FUNCTION public.next_unique_slug(
  p_table regclass,
  p_base_slug text,
  p_exclude_id text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  slug_candidate text;
  n int := 0;
  id_col text;
  exists_count int;
BEGIN
  slug_candidate := nullif(trim(p_base_slug), '');
  if slug_candidate is null or slug_candidate = '' then
    slug_candidate := 'slug';
  end if;

  -- Get primary key column name (id for our tables)
  id_col := 'id';

  LOOP
    if n > 0 then
      slug_candidate := p_base_slug || '-' || n;
    end if;
    EXECUTE format(
      'SELECT count(*)::int FROM %s WHERE slug = $1 AND ($2::text IS NULL OR %I::text <> $2)',
      p_table, id_col
    ) INTO exists_count USING slug_candidate, p_exclude_id;
    if exists_count = 0 then
      RETURN slug_candidate;
    end if;
    n := n + 1;
  END LOOP;
END;
$$;
-- 3. Add slug column to business_categories
ALTER TABLE public.business_categories
  ADD COLUMN IF NOT EXISTS slug text;
-- 4. Add slug column to subcategories
ALTER TABLE public.subcategories
  ADD COLUMN IF NOT EXISTS slug text;
-- 5. Add slug column to businesses
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS slug text;
-- 6. Add slug column to parishes
ALTER TABLE public.parishes
  ADD COLUMN IF NOT EXISTS slug text;
-- 7. Backfill business_categories (order matters for subcategories)
UPDATE public.business_categories c
SET slug = sub.s
FROM (
  SELECT id,
    public.next_unique_slug(
      'public.business_categories'::regclass,
      public.slugify(name),
      id::text
    ) AS s
  FROM public.business_categories
) sub
WHERE c.id = sub.id AND (c.slug IS NULL OR c.slug = '');
-- 8. Backfill subcategories: slug = category_slug + '-' + slugify(subcategory name)
UPDATE public.subcategories sc
SET slug = sub.s
FROM (
  SELECT sc2.id,
    public.next_unique_slug(
      'public.subcategories'::regclass,
      (SELECT bc.slug FROM public.business_categories bc WHERE bc.id = sc2.category_id) || '-' || public.slugify(sc2.name),
      sc2.id::text
    ) AS s
  FROM public.subcategories sc2
) sub
WHERE sc.id = sub.id AND (sc.slug IS NULL OR sc.slug = '');
-- 9. Backfill parishes
UPDATE public.parishes p
SET slug = sub.s
FROM (
  SELECT id,
    public.next_unique_slug('public.parishes'::regclass, public.slugify(name), id::text) AS s
  FROM public.parishes
) sub
WHERE p.id = sub.id AND (p.slug IS NULL OR p.slug = '');
-- 10. Backfill businesses (allow duplicate base names -> -1, -2)
UPDATE public.businesses b
SET slug = sub.s
FROM (
  SELECT id,
    public.next_unique_slug('public.businesses'::regclass, public.slugify(name), id::text) AS s
  FROM public.businesses
) sub
WHERE b.id = sub.id AND (b.slug IS NULL OR b.slug = '');
-- 11. Backfill blog_posts slug from title where slug is null (if any)
UPDATE public.blog_posts bp
SET slug = sub.s
FROM (
  SELECT id,
    public.next_unique_slug('public.blog_posts'::regclass, public.slugify(title), id::text) AS s
  FROM public.blog_posts
  WHERE slug IS NULL OR slug = ''
) sub
WHERE bp.id = sub.id;
-- 12. Unique constraints on slug
ALTER TABLE public.business_categories
  DROP CONSTRAINT IF EXISTS business_categories_slug_key;
ALTER TABLE public.business_categories
  ADD CONSTRAINT business_categories_slug_key UNIQUE (slug);
ALTER TABLE public.subcategories
  DROP CONSTRAINT IF EXISTS subcategories_slug_key;
ALTER TABLE public.subcategories
  ADD CONSTRAINT subcategories_slug_key UNIQUE (slug);
ALTER TABLE public.businesses
  DROP CONSTRAINT IF EXISTS businesses_slug_key;
ALTER TABLE public.businesses
  ADD CONSTRAINT businesses_slug_key UNIQUE (slug);
ALTER TABLE public.parishes
  DROP CONSTRAINT IF EXISTS parishes_slug_key;
ALTER TABLE public.parishes
  ADD CONSTRAINT parishes_slug_key UNIQUE (slug);
-- blog_posts already has unique(slug) typically; ensure it
ALTER TABLE public.blog_posts
  DROP CONSTRAINT IF EXISTS blog_posts_slug_key;
ALTER TABLE public.blog_posts
  ADD CONSTRAINT blog_posts_slug_key UNIQUE (slug);
-- 13. Trigger: business_categories — set slug from name if null
CREATE OR REPLACE FUNCTION public.set_business_categories_slug()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.slug IS NULL OR trim(NEW.slug) = '' THEN
    NEW.slug := public.next_unique_slug(
      'public.business_categories'::regclass,
      public.slugify(NEW.name),
      CASE WHEN TG_OP = 'UPDATE' THEN NEW.id::text ELSE NULL END
    );
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_business_categories_slug ON public.business_categories;
CREATE TRIGGER trigger_business_categories_slug
  BEFORE INSERT OR UPDATE OF name, slug ON public.business_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_business_categories_slug();
-- 14. Trigger: subcategories — slug = category_slug + '-' + slugify(name)
CREATE OR REPLACE FUNCTION public.set_subcategories_slug()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  cat_slug text;
  base text;
BEGIN
  IF NEW.slug IS NULL OR trim(NEW.slug) = '' THEN
    SELECT slug INTO cat_slug FROM public.business_categories WHERE id = NEW.category_id;
    base := coalesce(cat_slug, 'cat') || '-' || public.slugify(NEW.name);
    NEW.slug := public.next_unique_slug(
      'public.subcategories'::regclass,
      base,
      CASE WHEN TG_OP = 'UPDATE' THEN NEW.id::text ELSE NULL END
    );
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_subcategories_slug ON public.subcategories;
CREATE TRIGGER trigger_subcategories_slug
  BEFORE INSERT OR UPDATE OF name, category_id, slug ON public.subcategories
  FOR EACH ROW EXECUTE FUNCTION public.set_subcategories_slug();
-- 15. Trigger: businesses — slug from name; duplicates get -1, -2
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
DROP TRIGGER IF EXISTS trigger_businesses_slug ON public.businesses;
CREATE TRIGGER trigger_businesses_slug
  BEFORE INSERT OR UPDATE OF name, slug ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.set_businesses_slug();
-- 16. Trigger: parishes — slug from name
CREATE OR REPLACE FUNCTION public.set_parishes_slug()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.slug IS NULL OR trim(NEW.slug) = '' THEN
    NEW.slug := public.next_unique_slug(
      'public.parishes'::regclass,
      public.slugify(NEW.name),
      CASE WHEN TG_OP = 'UPDATE' THEN NEW.id::text ELSE NULL END
    );
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_parishes_slug ON public.parishes;
CREATE TRIGGER trigger_parishes_slug
  BEFORE INSERT OR UPDATE OF name, slug ON public.parishes
  FOR EACH ROW EXECUTE FUNCTION public.set_parishes_slug();
-- 17. Trigger: blog_posts — slug from title if null
CREATE OR REPLACE FUNCTION public.set_blog_posts_slug()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.slug IS NULL OR trim(NEW.slug) = '' THEN
    NEW.slug := public.next_unique_slug(
      'public.blog_posts'::regclass,
      public.slugify(NEW.title),
      CASE WHEN TG_OP = 'UPDATE' THEN NEW.id::text ELSE NULL END
    );
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_blog_posts_slug ON public.blog_posts;
CREATE TRIGGER trigger_blog_posts_slug
  BEFORE INSERT OR UPDATE OF title, slug ON public.blog_posts
  FOR EACH ROW EXECUTE FUNCTION public.set_blog_posts_slug();
-- Indexes for lookups by slug
CREATE INDEX IF NOT EXISTS idx_business_categories_slug ON public.business_categories(slug);
CREATE INDEX IF NOT EXISTS idx_subcategories_slug ON public.subcategories(slug);
CREATE INDEX IF NOT EXISTS idx_businesses_slug ON public.businesses(slug);
CREATE INDEX IF NOT EXISTS idx_parishes_slug ON public.parishes(slug);
