-- Allow admin to hard-delete a business. Cascading deletes are handled by FK ON DELETE CASCADE
-- on dependent tables (e.g. business_parishes, form_submissions per docs).
CREATE POLICY "businesses_delete_admin"
  ON public.businesses
  FOR DELETE
  TO authenticated
  USING (has_role(auth.uid(), 'admin'));
