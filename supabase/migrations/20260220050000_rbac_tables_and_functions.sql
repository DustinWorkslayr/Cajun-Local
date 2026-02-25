-- Tables and helper functions required by business_parishes RLS and other policies.
-- Run after 20260220000000 (businesses exists); before 20260221000000 (add_business_parishes).

-- 1. business_managers (referenced by claim_approved trigger and is_business_manager)
CREATE TABLE IF NOT EXISTS public.business_managers (
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'owner',
  PRIMARY KEY (business_id, user_id)
);

-- 2. user_roles (referenced by claim_approved trigger and has_role)
CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL
);

-- 3. has_role(user_id, role_name) — used by parishes and business_parishes admin policies
DROP FUNCTION IF EXISTS public.has_role(uuid, text);
CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_role text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id AND role::text = p_role
  );
$$;

-- 4. is_business_manager(user_id, business_id) — used by business_parishes and punch_card RPCs
-- Use param names _user_id, _business_id so CREATE OR REPLACE works when replacing existing function.
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
    SELECT 1 FROM public.businesses
    WHERE id = _business_id AND created_by = _user_id
  );
$$;
