-- Fake data for testing. Run via: supabase db reset  OR  supabase db seed
-- Seed runs as DB owner (RLS bypassed). Intended for fresh/local DB.

-- 1. business_categories (bucket: eat | hire | shop | explore)
INSERT INTO public.business_categories (id, name, icon, sort_order, bucket) VALUES
  ('11111111-1111-1111-1111-111111111101', 'Restaurants', 'restaurant', 1, 'eat'),
  ('11111111-1111-1111-1111-111111111102', 'Music & Events', 'music_note', 2, 'explore'),
  ('11111111-1111-1111-1111-111111111103', 'Shopping', 'store', 3, 'shop')
ON CONFLICT (id) DO UPDATE SET bucket = EXCLUDED.bucket;

-- 2. subcategories
INSERT INTO public.subcategories (id, name, category_id) VALUES
  ('22222222-2222-2222-2222-222222222201', 'Cajun', '11111111-1111-1111-1111-111111111101'),
  ('22222222-2222-2222-2222-222222222202', 'Seafood', '11111111-1111-1111-1111-111111111101'),
  ('22222222-2222-2222-2222-222222222203', 'Zydeco', '11111111-1111-1111-1111-111111111102'),
  ('22222222-2222-2222-2222-222222222204', 'Local crafts', '11111111-1111-1111-1111-111111111103')
ON CONFLICT (id) DO NOTHING;

-- 3. businesses (category_id from above; created_by omitted if column nullable)
INSERT INTO public.businesses (id, name, status, category_id, city, parish, state, address, phone, description, tagline) VALUES
  ('33333333-3333-3333-3333-333333333301', 'Bayou Bites', 'approved', '11111111-1111-1111-1111-111111111101', 'Lafayette', 'lafayette', 'LA', '412 Bayou Teche Rd, Lafayette, LA 70501', '(337) 555-0142', 'Family-owned since 1982. Authentic gumbo and po''boys.', 'Authentic gumbo & po''boys'),
  ('33333333-3333-3333-3333-333333333302', 'Zydeco Hall', 'approved', '11111111-1111-1111-1111-111111111102', 'Lafayette', 'lafayette', 'LA', '200 Festival Way, Lafayette, LA 70506', '(337) 555-0198', 'Live Cajun and zydeco. Dance floor and full bar.', 'Live music & dancing'),
  ('33333333-3333-3333-3333-333333333303', 'Cajun Spice Market', 'approved', '11111111-1111-1111-1111-111111111103', 'Breaux Bridge', 'st_martin', 'LA', '101 Main St, Breaux Bridge, LA 70517', '(337) 555-0221', 'Cajun spices, hot sauces, and local crafts.', 'Local spices & crafts')
ON CONFLICT (id) DO NOTHING;

-- 4. business_parishes
INSERT INTO public.business_parishes (business_id, parish_id) VALUES
  ('33333333-3333-3333-3333-333333333301', 'lafayette'),
  ('33333333-3333-3333-3333-333333333302', 'lafayette'),
  ('33333333-3333-3333-3333-333333333303', 'st_martin')
ON CONFLICT (business_id, parish_id) DO NOTHING;

-- 5. business_subcategories
INSERT INTO public.business_subcategories (business_id, subcategory_id) VALUES
  ('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222201'),
  ('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222202'),
  ('33333333-3333-3333-3333-333333333302', '22222222-2222-2222-2222-222222222203'),
  ('33333333-3333-3333-3333-333333333303', '22222222-2222-2222-2222-222222222204')
ON CONFLICT (business_id, subcategory_id) DO NOTHING;

-- 6. business_hours (day_of_week: monday..sunday)
INSERT INTO public.business_hours (business_id, day_of_week, open_time, close_time, is_closed) VALUES
  ('33333333-3333-3333-3333-333333333301', 'monday', '11:00', '21:00', false),
  ('33333333-3333-3333-3333-333333333301', 'tuesday', '11:00', '21:00', false),
  ('33333333-3333-3333-3333-333333333301', 'wednesday', '11:00', '21:00', false),
  ('33333333-3333-3333-3333-333333333301', 'thursday', '11:00', '21:00', false),
  ('33333333-3333-3333-3333-333333333301', 'friday', '11:00', '22:00', false),
  ('33333333-3333-3333-3333-333333333301', 'saturday', '11:00', '22:00', false),
  ('33333333-3333-3333-3333-333333333301', 'sunday', '12:00', '20:00', false),
  ('33333333-3333-3333-3333-333333333302', 'thursday', '18:00', '02:00', false),
  ('33333333-3333-3333-3333-333333333302', 'friday', '18:00', '02:00', false),
  ('33333333-3333-3333-3333-333333333302', 'saturday', '18:00', '02:00', false),
  ('33333333-3333-3333-3333-333333333302', 'sunday', '16:00', '00:00', false),
  ('33333333-3333-3333-3333-333333333303', 'monday', '09:00', '18:00', false),
  ('33333333-3333-3333-3333-333333333303', 'tuesday', '09:00', '18:00', false),
  ('33333333-3333-3333-3333-333333333303', 'wednesday', '09:00', '18:00', false),
  ('33333333-3333-3333-3333-333333333303', 'thursday', '09:00', '18:00', false),
  ('33333333-3333-3333-3333-333333333303', 'friday', '09:00', '18:00', false),
  ('33333333-3333-3333-3333-333333333303', 'saturday', '09:00', '18:00', false),
  ('33333333-3333-3333-3333-333333333303', 'sunday', '10:00', '16:00', false)
ON CONFLICT (business_id, day_of_week) DO NOTHING;

-- 7. deals (deal_type: percentage, fixed, bogo, freebie, other, flash, member_only)
INSERT INTO public.deals (id, business_id, title, deal_type, status, description, is_active, start_date, end_date) VALUES
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333301', '10% off lunch', 'percentage', 'approved', 'Valid Mon–Fri 11am–2pm. Dine-in only.', true, now()::date::timestamptz, (now() + interval '90 days')::timestamptz),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333301', 'Free dessert with entrée', 'freebie', 'approved', 'Order any entrée, get bread pudding or pecan pie on the house.', true, now()::date::timestamptz, (now() + interval '60 days')::timestamptz),
  (gen_random_uuid(), '33333333-3333-3333-3333-333333333302', 'Half-price cover on Thursday', 'percentage', 'approved', 'Show this deal at the door for half-price cover.', true, now()::date::timestamptz, (now() + interval '30 days')::timestamptz);

-- 8. blog_posts (slug unique; status approved for public visibility)
INSERT INTO public.blog_posts (id, slug, title, body, status, published_at) VALUES
  (gen_random_uuid(), 'welcome-to-cajun-local', 'Welcome to Cajun Local', '<p>Discover local businesses, deals, and events in Acadiana.</p><p>We’re here to connect you with the best of Louisiana.</p>', 'approved', now()),
  (gen_random_uuid(), 'best-gumbo-in-town', 'Best Gumbo in Town', '<p>Our roundup of top gumbo spots this season.</p><h2>Bayou favorites</h2><p>From classic chicken and andouille to seafood gumbo.</p>', 'approved', now() - interval '2 days')
ON CONFLICT (slug) DO NOTHING;

-- 9. notification_banners (optional; fixed id so re-seed does not duplicate)
INSERT INTO public.notification_banners (id, title, message, is_active) VALUES
  ('44444444-4444-4444-4444-444444444401', 'Welcome', 'Thanks for using Cajun Local. Check out our latest deals and events!', true)
ON CONFLICT (id) DO NOTHING;

-- 10. business_amenities (sample: 4 per business; amenity IDs from amenities migration)
INSERT INTO public.business_amenities (business_id, amenity_id) VALUES
  ('33333333-3333-3333-3333-333333333301', 'a0000001-0001-4001-8001-000000000001'),
  ('33333333-3333-3333-3333-333333333301', 'a0000001-0001-4001-8001-000000000002'),
  ('33333333-3333-3333-3333-333333333301', 'a0000002-0002-4002-8002-000000000005'),
  ('33333333-3333-3333-3333-333333333301', 'a0000002-0002-4002-8002-000000000006'),
  ('33333333-3333-3333-3333-333333333302', 'a0000001-0001-4001-8001-000000000001'),
  ('33333333-3333-3333-3333-333333333302', 'a0000001-0001-4001-8001-000000000012'),
  ('33333333-3333-3333-3333-333333333302', 'a0000005-0005-4005-8005-000000000002'),
  ('33333333-3333-3333-3333-333333333302', 'a0000005-0005-4005-8005-000000000007'),
  ('33333333-3333-3333-3333-333333333303', 'a0000001-0001-4001-8001-000000000006'),
  ('33333333-3333-3333-3333-333333333303', 'a0000004-0004-4004-8004-000000000002'),
  ('33333333-3333-3333-3333-333333333303', 'a0000004-0004-4004-8004-000000000004'),
  ('33333333-3333-3333-3333-333333333303', 'a0000004-0004-4004-8004-000000000008')
ON CONFLICT (business_id, amenity_id) DO NOTHING;
