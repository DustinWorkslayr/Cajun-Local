-- Admin: read amenities via RPC so the admin UI always sees rows (bypasses RLS quirks).
-- Requires: has_role() from 20260220050000_rbac_tables_and_functions.

CREATE OR REPLACE FUNCTION public.get_amenities_for_admin(p_bucket text DEFAULT NULL)
RETURNS SETOF public.amenities
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'insufficient_privilege: admin role required';
  END IF;
  RETURN QUERY
  SELECT * FROM public.amenities
  WHERE (p_bucket IS NULL OR bucket = p_bucket)
  ORDER BY bucket, sort_order;
END;
$$;

COMMENT ON FUNCTION public.get_amenities_for_admin(text) IS 'Admin only: returns amenities (optionally filtered by bucket). Use for admin amenities management UI.';
