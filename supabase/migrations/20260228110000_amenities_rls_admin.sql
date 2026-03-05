-- Amenities master table: public read; admin can insert/update/delete.
-- Requires: has_role() from 20260220050000_rbac_tables_and_functions.

ALTER TABLE public.amenities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "amenities_select_public" ON public.amenities;
CREATE POLICY "amenities_select_public"
  ON public.amenities FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "amenities_insert_admin" ON public.amenities;
CREATE POLICY "amenities_insert_admin"
  ON public.amenities FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "amenities_update_admin" ON public.amenities;
CREATE POLICY "amenities_update_admin"
  ON public.amenities FOR UPDATE
  USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "amenities_delete_admin" ON public.amenities;
CREATE POLICY "amenities_delete_admin"
  ON public.amenities FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));
