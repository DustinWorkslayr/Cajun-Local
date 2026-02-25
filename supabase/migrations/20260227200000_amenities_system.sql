-- Amenity system: 50 launch-ready amenities (15 global + 10 eat + 10 hire + 8 shop + 7 explore).
-- Free businesses: max 4 amenities. Subscribed (Local+ or Local Partner): max 8.
-- App shows Global + bucket-specific amenities only (bucket from business's category).

-- 1. Amenities master table (bucket = 'global' | 'eat' | 'hire' | 'shop' | 'explore')
CREATE TABLE IF NOT EXISTS public.amenities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  bucket text NOT NULL CHECK (bucket IN ('global', 'eat', 'hire', 'shop', 'explore')),
  sort_order integer NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_amenities_bucket ON public.amenities(bucket);
CREATE INDEX IF NOT EXISTS idx_amenities_slug ON public.amenities(slug);

COMMENT ON TABLE public.amenities IS 'Master list of 50 amenities; bucket determines which categories can use them (global = all).';

-- 2. Business–amenity junction (which amenities a business has selected)
CREATE TABLE IF NOT EXISTS public.business_amenities (
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  amenity_id uuid NOT NULL REFERENCES public.amenities(id) ON DELETE CASCADE,
  PRIMARY KEY (business_id, amenity_id)
);

CREATE INDEX IF NOT EXISTS idx_business_amenities_business_id ON public.business_amenities(business_id);
CREATE INDEX IF NOT EXISTS idx_business_amenities_amenity_id ON public.business_amenities(amenity_id);

ALTER TABLE public.business_amenities ENABLE ROW LEVEL SECURITY;

-- RLS: anyone can read; only manager or admin can insert/delete
CREATE POLICY "business_amenities_select_public"
  ON public.business_amenities FOR SELECT
  USING (true);

CREATE POLICY "business_amenities_insert_manager_or_admin"
  ON public.business_amenities FOR INSERT
  WITH CHECK (
    public.is_business_manager(auth.uid(), business_id) OR public.has_role(auth.uid(), 'admin')
  );

CREATE POLICY "business_amenities_delete_manager_or_admin"
  ON public.business_amenities FOR DELETE
  USING (
    public.is_business_manager(auth.uid(), business_id) OR public.has_role(auth.uid(), 'admin')
  );

-- 3. Max amenities by tier: free = 4, subscribed (basic/premium/enterprise) = 8
CREATE OR REPLACE FUNCTION public.max_amenities_for_tier(p_tier text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  p_tier := lower(trim(COALESCE(p_tier, 'free')));
  IF p_tier IN ('basic', 'premium', 'enterprise') THEN
    RETURN 8;
  END IF;
  RETURN 4;
END;
$$;

-- 4. Get business tier (reuse deal logic: no active sub = free)
CREATE OR REPLACE FUNCTION public.get_business_tier_for_amenities(p_business_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  RETURN public.get_business_tier_for_deals(p_business_id);
END;
$$;

-- 5. Check amenity is allowed for business's bucket (global OR matches category bucket)
CREATE OR REPLACE FUNCTION public.amenity_allowed_for_business(p_business_id uuid, p_amenity_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_cat_bucket text;
  v_amenity_bucket text;
BEGIN
  SELECT a.bucket INTO v_amenity_bucket FROM public.amenities a WHERE a.id = p_amenity_id;
  IF v_amenity_bucket IS NULL THEN
    RETURN false;
  END IF;
  IF v_amenity_bucket = 'global' THEN
    RETURN true;
  END IF;
  SELECT bc.bucket INTO v_cat_bucket
  FROM public.businesses b
  JOIN public.business_categories bc ON bc.id = b.category_id
  WHERE b.id = p_business_id;
  RETURN v_cat_bucket = v_amenity_bucket;
END;
$$;

-- 6. Trigger: enforce max amenities by tier and bucket eligibility
CREATE OR REPLACE FUNCTION public.check_business_amenity_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_tier text;
  v_max integer;
  v_count integer;
BEGIN
  IF NOT public.amenity_allowed_for_business(NEW.business_id, NEW.amenity_id) THEN
    RAISE EXCEPTION 'This amenity is not available for your business category. Choose from Global or your category (Eat/Hire/Shop/Explore).';
  END IF;

  v_tier := public.get_business_tier_for_amenities(NEW.business_id);
  v_max := public.max_amenities_for_tier(v_tier);

  SELECT count(*)::integer INTO v_count
  FROM public.business_amenities
  WHERE business_id = NEW.business_id;

  IF v_count >= v_max THEN
    RAISE EXCEPTION 'Amenity limit reached. Free listings: % amenities. Subscribed (Local+ or Local Partner): % amenities.', 4, 8;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_check_business_amenity_insert ON public.business_amenities;
CREATE TRIGGER trigger_check_business_amenity_insert
  BEFORE INSERT ON public.business_amenities
  FOR EACH ROW
  EXECUTE FUNCTION public.check_business_amenity_insert();

-- 7. Seed: 50 amenities exactly (idempotent by slug)
-- GLOBAL (15)
INSERT INTO public.amenities (id, name, slug, bucket, sort_order) VALUES
  ('a0000001-0001-4001-8001-000000000001', 'Online Booking', 'online-booking', 'global', 1),
  ('a0000001-0001-4001-8001-000000000002', 'Walk-Ins Welcome', 'walk-ins-welcome', 'global', 2),
  ('a0000001-0001-4001-8001-000000000003', 'Appointment Required', 'appointment-required', 'global', 3),
  ('a0000001-0001-4001-8001-000000000004', '24/7 Service', '24-7-service', 'global', 4),
  ('a0000001-0001-4001-8001-000000000005', 'Emergency Service', 'emergency-service', 'global', 5),
  ('a0000001-0001-4001-8001-000000000006', 'Accepts Credit Cards', 'accepts-credit-cards', 'global', 6),
  ('a0000001-0001-4001-8001-000000000007', 'Apple Pay / Google Pay', 'apple-pay-google-pay', 'global', 7),
  ('a0000001-0001-4001-8001-000000000008', 'Cash Only', 'cash-only', 'global', 8),
  ('a0000001-0001-4001-8001-000000000009', 'Financing Available', 'financing-available', 'global', 9),
  ('a0000001-0001-4001-8001-000000000010', 'Wheelchair Accessible', 'wheelchair-accessible', 'global', 10),
  ('a0000001-0001-4001-8001-000000000011', 'Handicap Parking', 'handicap-parking', 'global', 11),
  ('a0000001-0001-4001-8001-000000000012', 'Family Friendly', 'family-friendly', 'global', 12),
  ('a0000001-0001-4001-8001-000000000013', 'Pet Friendly', 'pet-friendly', 'global', 13)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, bucket = EXCLUDED.bucket, sort_order = EXCLUDED.sort_order;

-- EAT (10)
INSERT INTO public.amenities (id, name, slug, bucket, sort_order) VALUES
  ('a0000002-0002-4002-8002-000000000001', 'Outdoor Seating', 'outdoor-seating', 'eat', 1),
  ('a0000002-0002-4002-8002-000000000002', 'Live Music', 'live-music', 'eat', 2),
  ('a0000002-0002-4002-8002-000000000003', 'Drive-Thru', 'drive-thru', 'eat', 3),
  ('a0000002-0002-4002-8002-000000000004', 'Delivery', 'delivery', 'eat', 4),
  ('a0000002-0002-4002-8002-000000000005', 'Takeout', 'takeout', 'eat', 5),
  ('a0000002-0002-4002-8002-000000000006', 'Dine-In', 'dine-in', 'eat', 6),
  ('a0000002-0002-4002-8002-000000000007', 'Catering Available', 'catering-available', 'eat', 7),
  ('a0000002-0002-4002-8002-000000000008', 'Private Dining Room', 'private-dining-room', 'eat', 8),
  ('a0000002-0002-4002-8002-000000000009', 'Happy Hour', 'happy-hour', 'eat', 9),
  ('a0000002-0002-4002-8002-000000000010', 'Waterfront Seating', 'waterfront-seating', 'eat', 10)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, bucket = EXCLUDED.bucket, sort_order = EXCLUDED.sort_order;

-- HIRE (10)
INSERT INTO public.amenities (id, name, slug, bucket, sort_order) VALUES
  ('a0000003-0003-4003-8003-000000000001', 'Licensed', 'licensed', 'hire', 1),
  ('a0000003-0003-4003-8003-000000000002', 'Insured', 'insured', 'hire', 2),
  ('a0000003-0003-4003-8003-000000000003', 'Bonded', 'bonded', 'hire', 3),
  ('a0000003-0003-4003-8003-000000000004', 'Free Consultation', 'free-consultation', 'hire', 4),
  ('a0000003-0003-4003-8003-000000000005', 'Free Estimates', 'free-estimates', 'hire', 5),
  ('a0000003-0003-4003-8003-000000000006', 'Same-Day Service', 'same-day-service', 'hire', 6),
  ('a0000003-0003-4003-8003-000000000007', 'Mobile Service', 'mobile-service', 'hire', 7),
  ('a0000003-0003-4003-8003-000000000008', 'On-Site Service', 'on-site-service', 'hire', 8),
  ('a0000003-0003-4003-8003-000000000009', 'After-Hours Service', 'after-hours-service', 'hire', 9),
  ('a0000003-0003-4003-8003-000000000010', 'Warranty Offered', 'warranty-offered', 'hire', 10)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, bucket = EXCLUDED.bucket, sort_order = EXCLUDED.sort_order;

-- SHOP (8)
INSERT INTO public.amenities (id, name, slug, bucket, sort_order) VALUES
  ('a0000004-0004-4004-8004-000000000001', 'Online Store', 'online-store', 'shop', 1),
  ('a0000004-0004-4004-8004-000000000002', 'In-Store Pickup', 'in-store-pickup', 'shop', 2),
  ('a0000004-0004-4004-8004-000000000003', 'Same-Day Pickup', 'same-day-pickup', 'shop', 3),
  ('a0000004-0004-4004-8004-000000000004', 'Shipping Available', 'shipping-available', 'shop', 4),
  ('a0000004-0004-4004-8004-000000000005', 'Custom Orders', 'custom-orders', 'shop', 5),
  ('a0000004-0004-4004-8004-000000000006', 'Layaway Available', 'layaway-available', 'shop', 6),
  ('a0000004-0004-4004-8004-000000000007', 'Price Matching', 'price-matching', 'shop', 7),
  ('a0000004-0004-4004-8004-000000000008', 'Gift Cards Available', 'gift-cards-available', 'shop', 8)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, bucket = EXCLUDED.bucket, sort_order = EXCLUDED.sort_order;

-- EXPLORE (7)
INSERT INTO public.amenities (id, name, slug, bucket, sort_order) VALUES
  ('a0000005-0005-4005-8005-000000000001', 'Guided Tours', 'guided-tours', 'explore', 1),
  ('a0000005-0005-4005-8005-000000000002', 'Self-Guided', 'self-guided', 'explore', 2),
  ('a0000005-0005-4005-8005-000000000003', 'Kid Friendly', 'kid-friendly', 'explore', 3),
  ('a0000005-0005-4005-8005-000000000004', 'Pet Friendly', 'pet-friendly-explore', 'explore', 4),
  ('a0000005-0005-4005-8005-000000000005', 'Indoor Activity', 'indoor-activity', 'explore', 5),
  ('a0000005-0005-4005-8005-000000000006', 'Outdoor Activity', 'outdoor-activity', 'explore', 6),
  ('a0000005-0005-4005-8005-000000000007', 'Event Hosting', 'event-hosting', 'explore', 7)
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, bucket = EXCLUDED.bucket, sort_order = EXCLUDED.sort_order;