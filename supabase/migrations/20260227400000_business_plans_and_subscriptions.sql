-- business_plans and business_subscriptions for subscription tab and tier enforcement.
-- Referenced by 20260221180000 (get_business_tier_for_deals, triggers).

-- 1. business_plans: tier definitions (free, basic, premium, enterprise)
CREATE TABLE IF NOT EXISTS public.business_plans (
  id text PRIMARY KEY,
  name text NOT NULL,
  tier text NOT NULL,
  price_monthly numeric NOT NULL DEFAULT 0,
  price_yearly numeric NOT NULL DEFAULT 0,
  features jsonb DEFAULT '{}',
  max_locations integer NOT NULL DEFAULT 1,
  stripe_price_id_monthly text,
  stripe_price_id_yearly text,
  stripe_product_id text,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_plans_tier ON public.business_plans(tier);
CREATE INDEX IF NOT EXISTS idx_business_plans_sort ON public.business_plans(sort_order);

ALTER TABLE public.business_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_plans_select_public" ON public.business_plans;
CREATE POLICY "business_plans_select_public"
  ON public.business_plans FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "business_plans_insert_admin" ON public.business_plans;
CREATE POLICY "business_plans_insert_admin"
  ON public.business_plans FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "business_plans_update_admin" ON public.business_plans;
CREATE POLICY "business_plans_update_admin"
  ON public.business_plans FOR UPDATE
  USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "business_plans_delete_admin" ON public.business_plans;
CREATE POLICY "business_plans_delete_admin"
  ON public.business_plans FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));

-- 2. business_subscriptions: one per business, links to plan
CREATE TABLE IF NOT EXISTS public.business_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL UNIQUE REFERENCES public.businesses(id) ON DELETE CASCADE,
  plan_id text NOT NULL REFERENCES public.business_plans(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'trialing', 'canceled', 'past_due')),
  billing_interval text NOT NULL DEFAULT 'monthly',
  current_period_start timestamptz,
  current_period_end timestamptz,
  stripe_subscription_id text,
  stripe_customer_id text,
  canceled_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_subscriptions_business_id ON public.business_subscriptions(business_id);
CREATE INDEX IF NOT EXISTS idx_business_subscriptions_plan_id ON public.business_subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_business_subscriptions_status ON public.business_subscriptions(status);

ALTER TABLE public.business_subscriptions ENABLE ROW LEVEL SECURITY;

-- Admin can do everything; managers can SELECT own business subscription
DROP POLICY IF EXISTS "business_subscriptions_select_admin_or_manager" ON public.business_subscriptions;
CREATE POLICY "business_subscriptions_select_admin_or_manager"
  ON public.business_subscriptions FOR SELECT
  USING (
    public.has_role(auth.uid(), 'admin')
    OR public.is_business_manager(auth.uid(), business_id)
  );

DROP POLICY IF EXISTS "business_subscriptions_insert_admin" ON public.business_subscriptions;
CREATE POLICY "business_subscriptions_insert_admin"
  ON public.business_subscriptions FOR INSERT
  WITH CHECK (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "business_subscriptions_update_admin" ON public.business_subscriptions;
CREATE POLICY "business_subscriptions_update_admin"
  ON public.business_subscriptions FOR UPDATE
  USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "business_subscriptions_delete_admin" ON public.business_subscriptions;
CREATE POLICY "business_subscriptions_delete_admin"
  ON public.business_subscriptions FOR DELETE
  USING (public.has_role(auth.uid(), 'admin'));

-- 3. Seed default plans if none exist
INSERT INTO public.business_plans (id, name, tier, price_monthly, price_yearly, sort_order, is_active)
VALUES
  ('free', 'Free', 'free', 0, 0, 0, true),
  ('basic', 'Local+', 'basic', 29, 290, 1, true),
  ('premium', 'Local Partner', 'premium', 79, 790, 2, true),
  ('enterprise', 'Local Partner Plus', 'enterprise', 149, 1490, 3, true)
ON CONFLICT (id) DO NOTHING;
