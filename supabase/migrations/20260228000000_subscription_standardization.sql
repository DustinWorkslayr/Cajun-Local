-- Subscription architecture: one business per location; subscriptions per business; Cajun+ per user.
-- Adds owner_user_id, plan_type + revenuecat_product_id on business_subscriptions,
-- user_plans + user_subscriptions for Cajun+, and RLS so users manage only businesses they own.

-- 1. businesses: add owner_user_id (one owner per business; backfill from created_by)
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS owner_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

UPDATE public.businesses
  SET owner_user_id = created_by
  WHERE owner_user_id IS NULL AND created_by IS NOT NULL;

-- New rows: default owner to creator (app can set explicitly)
CREATE OR REPLACE FUNCTION public.set_business_owner_from_creator()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.owner_user_id IS NULL AND NEW.created_by IS NOT NULL THEN
    NEW.owner_user_id := NEW.created_by;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_business_owner_default ON public.businesses;
CREATE TRIGGER trigger_business_owner_default
  BEFORE INSERT ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.set_business_owner_from_creator();

-- is_business_manager: treat owner_user_id or created_by as owner
CREATE OR REPLACE FUNCTION public.is_business_manager(_user_id uuid, _business_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.business_managers
    WHERE business_id = _business_id AND user_id = _user_id
  )
  OR EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = _business_id
      AND (b.owner_user_id = _user_id OR b.created_by = _user_id)
  );
$$;

-- 2. business_subscriptions: plan_type (free | local_plus | partner) and revenuecat_product_id
ALTER TABLE public.business_subscriptions
  ADD COLUMN IF NOT EXISTS plan_type text
    CHECK (plan_type IS NULL OR plan_type IN ('free', 'local_plus', 'partner'));

ALTER TABLE public.business_subscriptions
  ADD COLUMN IF NOT EXISTS revenuecat_product_id text;

-- Backfill plan_type from existing plan_id
UPDATE public.business_subscriptions
  SET plan_type = CASE plan_id
    WHEN 'free' THEN 'free'
    WHEN 'basic' THEN 'local_plus'
    WHEN 'premium' THEN 'partner'
    WHEN 'enterprise' THEN 'partner'
    ELSE 'free'
  END
  WHERE plan_type IS NULL;

-- 3. user_plans (Cajun+ only; referenced by ask-local)
CREATE TABLE IF NOT EXISTS public.user_plans (
  id text PRIMARY KEY,
  name text NOT NULL,
  tier text NOT NULL,
  created_at timestamptz DEFAULT now()
);

INSERT INTO public.user_plans (id, name, tier)
VALUES ('cajun_plus', 'Cajun+', 'plus')
ON CONFLICT (id) DO NOTHING;

-- 4. user_subscriptions (one per user for Cajun+)
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id text NOT NULL REFERENCES public.user_plans(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'trialing', 'canceled', 'past_due')),
  billing_interval text NOT NULL DEFAULT 'monthly',
  current_period_start timestamptz,
  current_period_end timestamptz,
  revenuecat_product_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);

ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can read/update only their own user_subscription; insert/delete via service or admin if needed
DROP POLICY IF EXISTS "user_subscriptions_select_own" ON public.user_subscriptions;
CREATE POLICY "user_subscriptions_select_own"
  ON public.user_subscriptions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "user_subscriptions_update_own" ON public.user_subscriptions;
CREATE POLICY "user_subscriptions_update_own"
  ON public.user_subscriptions FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "user_subscriptions_insert_own" ON public.user_subscriptions;
CREATE POLICY "user_subscriptions_insert_own"
  ON public.user_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 5. RLS: businesses — SELECT/UPDATE for owner or manager (not only created_by)
DROP POLICY IF EXISTS "businesses_select_own" ON public.businesses;
CREATE POLICY "businesses_select_own"
  ON public.businesses
  FOR SELECT
  TO authenticated
  USING (
    owner_user_id = auth.uid()
    OR created_by = auth.uid()
    OR public.is_business_manager(auth.uid(), id)
  );

DROP POLICY IF EXISTS "businesses_update_own_or_manager" ON public.businesses;
CREATE POLICY "businesses_update_own_or_manager"
  ON public.businesses
  FOR UPDATE
  TO authenticated
  USING (
    owner_user_id = auth.uid()
    OR public.is_business_manager(auth.uid(), id)
  )
  WITH CHECK (
    owner_user_id = auth.uid()
    OR public.is_business_manager(auth.uid(), id)
  );

-- Comments
COMMENT ON COLUMN public.businesses.owner_user_id IS 'Canonical owner; one business per location.';
COMMENT ON COLUMN public.business_subscriptions.plan_type IS 'Standardized: free | local_plus | partner (RevenueCat).';
COMMENT ON COLUMN public.business_subscriptions.revenuecat_product_id IS 'e.g. local_plus_monthly, local_partner_monthly.';
