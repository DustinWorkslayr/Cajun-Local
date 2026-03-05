-- Ensure business_categories and subcategories are readable by anon/authenticated.
-- Reference data used by Choose for me, Explore, and public listing flows.
-- If RLS was enabled in Dashboard without policies, reads would return no rows; this fixes that.
-- Requires: has_role() from 20260220050000_rbac_tables_and_functions.

-- business_categories: public read; admin can insert/update/delete
ALTER TABLE public.business_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_categories_select_public" ON public.business_categories;
CREATE POLICY "business_categories_select_public"
  ON public.business_categories FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "business_categories_insert_admin" ON public.business_categories;
CREATE POLICY "business_categories_insert_admin"
  ON public.business_categories FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "business_categories_update_admin" ON public.business_categories;
CREATE POLICY "business_categories_update_admin"
  ON public.business_categories FOR UPDATE
  USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "business_categories_delete_admin" ON public.business_categories;
CREATE POLICY "business_categories_delete_admin"
  ON public.business_categories FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));

-- subcategories: public read; admin can insert/update/delete
ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "subcategories_select_public" ON public.subcategories;
CREATE POLICY "subcategories_select_public"
  ON public.subcategories FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "subcategories_insert_admin" ON public.subcategories;
CREATE POLICY "subcategories_insert_admin"
  ON public.subcategories FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "subcategories_update_admin" ON public.subcategories;
CREATE POLICY "subcategories_update_admin"
  ON public.subcategories FOR UPDATE
  USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "subcategories_delete_admin" ON public.subcategories;
CREATE POLICY "subcategories_delete_admin"
  ON public.subcategories FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));
