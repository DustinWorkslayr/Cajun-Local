-- Allow authenticated users to INSERT into businesses when they are the creator (created_by = auth.uid()).
-- Fixes 42501 (insufficient_privilege) when a user creates a listing from the app.
-- New businesses should be pending until admin approves; ensure status defaults to 'pending' if not set.

-- Policy: users can insert a row only when created_by equals their auth.uid()
CREATE POLICY "businesses_insert_own"
  ON public.businesses
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);
-- Ensure new rows default to pending (so user-created listings require approval)
ALTER TABLE public.businesses
  ALTER COLUMN status SET DEFAULT 'pending';
