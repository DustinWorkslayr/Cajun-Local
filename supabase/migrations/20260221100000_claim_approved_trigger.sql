-- When business_claims.status is set to 'approved', add the claimant to business_managers
-- and set user_roles.role to 'business_owner' (matches app behavior in admin_claim_detail_screen).
-- Requires: business_managers UNIQUE(business_id, user_id), user_roles UNIQUE(user_id) or PK(user_id).

CREATE OR REPLACE FUNCTION public.on_business_claim_approved()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status <> 'approved') THEN
    -- Add user as manager for the business (ignore if already exists)
    INSERT INTO public.business_managers (business_id, user_id, role)
    VALUES (NEW.business_id, NEW.user_id, 'owner')
    ON CONFLICT (business_id, user_id) DO NOTHING;

    -- Set or insert user_roles to business_owner
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.user_id, 'business_owner')
    ON CONFLICT (user_id) DO UPDATE SET role = 'business_owner';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trigger_on_business_claim_approved
  AFTER UPDATE ON public.business_claims
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_claim_approved();
