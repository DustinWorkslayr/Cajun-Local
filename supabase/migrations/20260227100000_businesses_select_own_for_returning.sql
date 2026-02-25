-- Allow creators to SELECT their own business row so that INSERT ... RETURNING id works.
-- Without this, insert(data).select('id').single() fails because the new row is status=pending
-- and a SELECT-only-for-approved policy would hide it.
CREATE POLICY "businesses_select_own"
  ON public.businesses
  FOR SELECT
  TO authenticated
  USING (created_by = auth.uid());
