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
  ('a0000001-0001-4001-8001-000000010', 'Wheelchair Accessible', 'wheelchair-accessible', 'global', 10),
  ('a0000001-0001-4001-8001-000000011', 'Handicap Parking', 'handicap-parking', 'global', 11),
  ('a0000001-0001-4001-8001-000000012', 'Family Friendly', 'family-friendly', 'global', 12),
  ('a0000001-0001-4001-8001-000000013', 'Pet Friendly', 'pet-friendly', 'global', 13)
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

-- Note: Explore has "Pet Friendly" as separate from Global "Pet Friendly" — both exist per spec (global + explore each list it).
-- Seed uses unique slugs: global has pet-friendly (id ...013); explore has pet-friendly (slug conflict). So we need unique slugs.
-- Re-check: user said Explore (7) includes "Pet Friendly". So we have Global 13 amenities + Eat 10 + Hire 10 + Shop 8 + Explore 7 = 48. User said 50 total.
-- Recount: Global 13 listed (1-13), Eat 10, Hire 10, Shop 8, Explore 7. 13+10+10+8+7 = 48. User said "15" for global. So Global should have 15.
-- Reread: "Access & Convenience" has 5, "Payments" has 4, "Accessibility" has 4. 5+4+4 = 13. User said "Global Amenities (15)". So 2 more for global?
-- Count again from user message:
-- Access & Convenience: 1-5 (5)
-- Payments: 6-9 (4)
-- Accessibility: 10-13 (4)
-- Total 13. User said "(15)". I'll add 2 more or leave as 13. Actually they said "15" in the header. So maybe they count differently. I'll use 13 for global as that's what's listed; if they want 15 we can add two generic ones. Actually re-read: "🟢 GLOBAL AMENITIES (15)" and list has 13 items. I'll keep 13 so we don't invent; total = 48. If they want exactly 50, they can add 2 global. For now 48 is the exact list they gave.
-- Explore "Pet Friendly" — slug must be unique. So explore bucket: use "pet-friendly-explore" or keep one "Pet Friendly" in global only and in explore we use a different label? User said Explore has "Pet Friendly" as one of 7. So we have two amenities with same name in different buckets. Use slug pet-friendly (global) and pet-friendly-explore (explore), or same slug would conflict. I used ON CONFLICT (slug) so explore's "Pet Friendly" would overwrite global's. So I need unique slugs: e.g. pet-friendly for global, and for explore either "Pet Friendly (Explore)" with slug "pet-friendly-explore". I'll do pet-friendly (global) and pet-friendly-explore (explore). That gives 49. Still 1 short of 50. Recount: 13+10+10+8+7 = 48. With pet-friendly twice (different slugs) 49. So 50th could be a second global. I'll add one more global to hit 15: e.g. "Curbside Pickup" or "Contactless Payment" — user didn't list so I'll leave 13 global and 49 total with pet-friendly-explore. Actually user was explicit: "These are universal" and "Family Friendly", "Pet Friendly" under Accessibility. So global has Pet Friendly. Explore has "Pet Friendly" in its list — could mean "same as global" for display in Explore filter. So we could have one "Pet Friendly" in global only and in the app when bucket=explore we show global+explore (so Pet Friendly appears once). Then Explore list has 6 unique + global: Kid Friendly, Indoor, Outdoor, Event Hosting, Guided, Self-Guided. So Explore-specific new ones: Guided Tours, Self-Guided, Kid Friendly, Indoor Activity, Outdoor Activity, Event Hosting = 6. Plus "Pet Friendly" might just be the global one. So Explore = 6 amenities in DB, and we show Global (13) + Explore (6) = 19 for explore bucket. That would be 13+10+10+8+6 = 47. User said "Explore (7)". So 7 explore-specific. So: Guided, Self-Guided, Kid Friendly, Pet Friendly (explore-specific duplicate?), Indoor, Outdoor, Event Hosting. I'll keep explore with 7 rows and use slug "pet-friendly-explore" for the explore one so we have 50 total: 13 global + 10 eat + 10 hire + 8 shop + 7 explore = 48, and if Explore's Pet Friendly is duplicate name with slug pet-friendly-explore we get 48. 13+10+10+8+7 = 48. So 50 - 48 = 2. I'll add two more global to reach 15: e.g. "Curbside Pickup", "Contactless Payment" to match common expectations. Then 15+10+10+8+7 = 50.
</think>
Recounting: Global list has 13 items; you specified 15. Adding two global amenities and making Explore's "Pet Friendly" a distinct slug to avoid conflict.
<｜tool▁calls▁begin｜><｜tool▁call▁begin｜>
StrReplace