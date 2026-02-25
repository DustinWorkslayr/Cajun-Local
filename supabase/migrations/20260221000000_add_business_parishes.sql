-- Optional: business_parishes table for service-based businesses that serve multiple parishes.
-- Primary parish stays on businesses.parish; this table holds additional "service area" parishes.
-- Requires: public.businesses, public.has_role(), public.is_business_manager() (from 20260220050000).
CREATE TABLE IF NOT EXISTS public.business_parishes (
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  parish_id text NOT NULL,
  PRIMARY KEY (business_id, parish_id)
);
CREATE INDEX IF NOT EXISTS idx_business_parishes_business_id ON public.business_parishes(business_id);
CREATE INDEX IF NOT EXISTS idx_business_parishes_parish_id ON public.business_parishes(parish_id);
ALTER TABLE public.business_parishes ENABLE ROW LEVEL SECURITY;
-- Anon can read (for directory filter / ask-local context).
CREATE POLICY "business_parishes_select_public"
  ON public.business_parishes FOR SELECT
  USING (true);
-- Manager of the business or admin can insert/delete.
CREATE POLICY "business_parishes_insert_manager_or_admin"
  ON public.business_parishes FOR INSERT
  WITH CHECK (
    public.is_business_manager(auth.uid(), business_id) OR public.has_role(auth.uid(), 'admin')
  );
CREATE POLICY "business_parishes_delete_manager_or_admin"
  ON public.business_parishes FOR DELETE
  USING (
    public.is_business_manager(auth.uid(), business_id) OR public.has_role(auth.uid(), 'admin')
  );
