-- RPC to return total favorites count per business (for display). Uses SECURITY DEFINER so count is visible to all.
CREATE OR REPLACE FUNCTION public.get_favorites_count(business_id uuid)
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT count(*)::bigint FROM favorites f WHERE f.business_id = get_favorites_count.business_id;
$$;
-- Grant execute to anon and authenticated so the app can call it
GRANT EXECUTE ON FUNCTION public.get_favorites_count(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_favorites_count(uuid) TO authenticated;
