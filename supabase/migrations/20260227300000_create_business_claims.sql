-- business_claims: ownership claim requests; admin approves. Required before claim_approved_trigger.
-- Applied after amenities so migration order matches remote (no insert-before).

CREATE TABLE IF NOT EXISTS public.business_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  claim_details text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_business_claims_business_id ON public.business_claims(business_id);
CREATE INDEX IF NOT EXISTS idx_business_claims_user_id ON public.business_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_business_claims_status ON public.business_claims(status);
CREATE INDEX IF NOT EXISTS idx_business_claims_created_at ON public.business_claims(created_at DESC);

ALTER TABLE public.business_claims ENABLE ROW LEVEL SECURITY;

-- User can insert own claim (user_id = auth.uid())
CREATE POLICY "business_claims_insert_own"
  ON public.business_claims FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- User can select own claims; admin can select all
CREATE POLICY "business_claims_select_own_or_admin"
  ON public.business_claims FOR SELECT
  USING (
    auth.uid() = user_id
    OR public.has_role(auth.uid(), 'admin')
  );

-- Only admin can update (e.g. set status to approved/rejected)
CREATE POLICY "business_claims_update_admin"
  ON public.business_claims FOR UPDATE
  USING (public.has_role(auth.uid(), 'admin'))
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

COMMENT ON TABLE public.business_claims IS 'Ownership claim requests; admin approves then trigger adds claimant to business_managers and user_roles.';
