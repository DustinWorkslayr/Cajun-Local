-- Admin amenities: use SECURITY DEFINER RPCs so insert/update/delete run with
-- definer rights and bypass RLS, while still enforcing has_role(auth.uid(), 'admin').
-- Fixes 42501 when the anon key + JWT context don't satisfy RLS WITH CHECK.

-- Requires: has_role() from 20260220050000_rbac_tables_and_functions.

-- Insert: single row
CREATE OR REPLACE FUNCTION public.insert_amenity_admin(payload jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'insufficient_privilege: admin role required';
  END IF;
  INSERT INTO public.amenities (id, name, slug, bucket, sort_order)
  VALUES (
    COALESCE((payload->>'id')::uuid, gen_random_uuid()),
    payload->>'name',
    payload->>'slug',
    COALESCE(payload->>'bucket', 'global'),
    COALESCE((payload->>'sort_order')::integer, 0)
  )
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- Update: by id, only provided keys
CREATE OR REPLACE FUNCTION public.update_amenity_admin(amenity_id uuid, payload jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'insufficient_privilege: admin role required';
  END IF;
  UPDATE public.amenities
  SET
    name = COALESCE(payload->>'name', name),
    slug = COALESCE(payload->>'slug', slug),
    bucket = COALESCE(payload->>'bucket', bucket),
    sort_order = COALESCE((payload->>'sort_order')::integer, sort_order)
  WHERE id = amenity_id;
END;
$$;

-- Batch update sort_order (for drag-and-drop reorder)
CREATE OR REPLACE FUNCTION public.update_amenities_sort_order(orders jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  item jsonb;
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'insufficient_privilege: admin role required';
  END IF;
  FOR item IN SELECT * FROM jsonb_array_elements(orders)
  LOOP
    UPDATE public.amenities
    SET sort_order = (item->>'sort_order')::integer
    WHERE id = (item->>'id')::uuid;
  END LOOP;
END;
$$;

-- Delete: by id
CREATE OR REPLACE FUNCTION public.delete_amenity_admin(amenity_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'insufficient_privilege: admin role required';
  END IF;
  DELETE FROM public.amenities WHERE id = amenity_id;
END;
$$;
