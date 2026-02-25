-- Fix 42501 row-level violation when users add a new business listing.
-- Ensures RLS is enabled and the INSERT policy exists so authenticated users can insert
-- a row with created_by = auth.uid() (and status pending).

-- Ensure RLS is enabled on businesses (idempotent)
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
-- Replace policy so it definitely exists with correct definition
DROP POLICY IF EXISTS "businesses_insert_own" ON public.businesses;
CREATE POLICY "businesses_insert_own"
  ON public.businesses
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);
-- Ensure new rows default to pending
ALTER TABLE public.businesses
  ALTER COLUMN status SET DEFAULT 'pending';
