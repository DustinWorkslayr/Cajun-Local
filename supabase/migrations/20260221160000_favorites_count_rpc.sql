-- RPC to return total favorites count per business (for display). Uses SECURITY DEFINER so count is visible to all.
-- Only create when public.favorites exists (table may be created outside this migration set).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'favorites') THEN
    EXECUTE '
      CREATE OR REPLACE FUNCTION public.get_favorites_count(business_id uuid)
      RETURNS bigint
      LANGUAGE sql
      SECURITY DEFINER
      SET search_path = public
      STABLE
      AS $inner$
        SELECT count(*)::bigint FROM public.favorites f WHERE f.business_id = get_favorites_count.business_id;
      $inner$';
    GRANT EXECUTE ON FUNCTION public.get_favorites_count(uuid) TO anon;
    GRANT EXECUTE ON FUNCTION public.get_favorites_count(uuid) TO authenticated;
  END IF;
END $$;
