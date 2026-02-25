-- Business subscription: deal creation and punch-card creation enforced by tier.
-- Tiers: free (1 simple deal), basic/Local+ (3 simple, scheduling), premium|enterprise/Local Partner (unlimited, all types + punch cards).
-- Extend deal_type enum and add tier helpers + triggers.

-- 1. Extend deal_type enum (simple: percentage, fixed, bogo, freebie, other; advanced: flash, member_only)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'flash' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'deal_type')) THEN
    ALTER TYPE public.deal_type ADD VALUE 'flash';
  END IF;
EXCEPTION
  WHEN undefined_object THEN
    -- deal_type might be a text column or different type; skip enum extension
    NULL;
END
$$;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'member_only' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'deal_type')) THEN
    ALTER TYPE public.deal_type ADD VALUE 'member_only';
  END IF;
EXCEPTION
  WHEN undefined_object THEN
    NULL;
END
$$;
-- 2. Get business plan tier for deal rules (active subscription only). Returns 'free' if no active sub.
CREATE OR REPLACE FUNCTION public.get_business_tier_for_deals(p_business_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_tier text;
BEGIN
  SELECT bp.tier::text INTO v_tier
  FROM business_subscriptions bs
  JOIN business_plans bp ON bp.id = bs.plan_id
  WHERE bs.business_id = p_business_id
    AND bs.status = 'active'
  LIMIT 1;
  RETURN COALESCE(v_tier, 'free');
END;
$$;
-- 3. Max active deals for tier: free=1, basic=3, premium|enterprise=999
CREATE OR REPLACE FUNCTION public.max_active_deals_for_tier(p_tier text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  p_tier := lower(trim(p_tier));
  IF p_tier IN ('premium', 'enterprise') THEN
    RETURN 999;
  END IF;
  IF p_tier = 'basic' THEN
    RETURN 3;
  END IF;
  RETURN 1;
END;
$$;
-- 4. Check if deal type is "advanced" (flash, member_only) — only Local Partner (premium/enterprise) can create
CREATE OR REPLACE FUNCTION public.is_advanced_deal_type(p_deal_type text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN lower(trim(p_deal_type)) IN ('flash', 'member_only');
END;
$$;
-- 5. Check deal insert/update allowed by tier (deal count + advanced type)
CREATE OR REPLACE FUNCTION public.check_deal_insert_allowed(
  p_business_id uuid,
  p_deal_type text,
  p_is_active boolean,
  p_exclude_deal_id text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier text;
  v_max integer;
  v_count integer;
BEGIN
  v_tier := get_business_tier_for_deals(p_business_id);

  -- Advanced deal types only for premium/enterprise
  IF is_advanced_deal_type(p_deal_type) THEN
    IF lower(v_tier) NOT IN ('premium', 'enterprise') THEN
      RAISE EXCEPTION 'Flash and Member-only deals require Local Partner. Upgrade your plan.';
    END IF;
  END IF;

  -- Active deal count limit
  IF p_is_active THEN
    v_max := max_active_deals_for_tier(v_tier);
    SELECT count(*)::integer INTO v_count
    FROM deals
    WHERE business_id = p_business_id
      AND is_active = true
      AND (p_exclude_deal_id IS NULL OR id::text <> p_exclude_deal_id);
    IF v_count >= v_max THEN
      RAISE EXCEPTION 'Deal limit reached for your plan (max % active deals). Upgrade to add more.', v_max;
    END IF;
  END IF;
END;
$$;
-- 6. Check punch card insert allowed — only premium/enterprise
CREATE OR REPLACE FUNCTION public.check_punch_card_insert_allowed(p_business_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier text;
BEGIN
  v_tier := get_business_tier_for_deals(p_business_id);
  IF lower(v_tier) NOT IN ('premium', 'enterprise') THEN
    RAISE EXCEPTION 'Loyalty punch cards require Local Partner. Upgrade your plan.';
  END IF;
END;
$$;
-- 7. Trigger function: deals
CREATE OR REPLACE FUNCTION public.on_deal_before_insert_update_tier_check()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM check_deal_insert_allowed(NEW.business_id, NEW.deal_type::text, COALESCE(NEW.is_active, false), NULL);
    RETURN NEW;
  END IF;
  -- UPDATE: re-check if is_active became true or deal_type changed
  IF (COALESCE(NEW.is_active, false) AND (OLD.is_active IS DISTINCT FROM NEW.is_active OR OLD.deal_type IS DISTINCT FROM NEW.deal_type))
     OR (NEW.deal_type IS DISTINCT FROM OLD.deal_type) THEN
    PERFORM check_deal_insert_allowed(NEW.business_id, NEW.deal_type::text, COALESCE(NEW.is_active, false), OLD.id::text);
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_deal_tier_check ON public.deals;
CREATE TRIGGER trigger_deal_tier_check
  BEFORE INSERT OR UPDATE ON public.deals
  FOR EACH ROW
  EXECUTE FUNCTION public.on_deal_before_insert_update_tier_check();
-- 8. Trigger function: punch_card_programs
CREATE OR REPLACE FUNCTION public.on_punch_card_before_insert_tier_check()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM check_punch_card_insert_allowed(NEW.business_id);
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_punch_card_tier_check ON public.punch_card_programs;
CREATE TRIGGER trigger_punch_card_tier_check
  BEFORE INSERT ON public.punch_card_programs
  FOR EACH ROW
  EXECUTE FUNCTION public.on_punch_card_before_insert_tier_check();
-- 9. On subscription downgrade: pause excess active deals for the business
CREATE OR REPLACE FUNCTION public.pause_excess_deals_for_business(p_business_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tier text;
  v_max integer;
  v_updated integer := 0;
BEGIN
  v_tier := get_business_tier_for_deals(p_business_id);
  v_max := max_active_deals_for_tier(v_tier);

  WITH keep AS (
    SELECT id FROM deals
    WHERE business_id = p_business_id AND is_active = true
    ORDER BY id
    LIMIT v_max
  )
  UPDATE deals d
  SET is_active = false
  WHERE d.business_id = p_business_id
    AND d.is_active = true
    AND d.id NOT IN (SELECT id FROM keep);

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;
-- 10. Trigger: when business_subscriptions plan_id or status changes, pause excess deals
CREATE OR REPLACE FUNCTION public.on_business_subscription_change_pause_excess_deals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only run when plan_id changed (downgrade/upgrade) or status changed
  IF (TG_OP = 'UPDATE' AND OLD.business_id IS NOT NULL)
     AND (NEW.plan_id IS DISTINCT FROM OLD.plan_id OR NEW.status IS DISTINCT FROM OLD.status) THEN
    IF NEW.status = 'active' THEN
      PERFORM pause_excess_deals_for_business(NEW.business_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_business_subscription_pause_excess_deals ON public.business_subscriptions;
CREATE TRIGGER trigger_business_subscription_pause_excess_deals
  AFTER UPDATE ON public.business_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_subscription_change_pause_excess_deals();
