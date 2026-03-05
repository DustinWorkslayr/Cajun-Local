-- user_roles: RLS so users can only read own row; only admin can list all and write.
-- Required for Admin Users screen: listForAdmin() and setRole()/deleteRole().
-- Without this, the table is either fully open (no RLS) or had policies defined outside this repo.

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Users can SELECT only their own role (for getRoleForUser / isAdmin checks).
DROP POLICY IF EXISTS "user_roles_select_own" ON public.user_roles;
CREATE POLICY "user_roles_select_own" ON public.user_roles
  FOR SELECT USING (auth.uid() = user_id);

-- Admin can SELECT all (for Admin Users list).
DROP POLICY IF EXISTS "user_roles_select_admin" ON public.user_roles;
CREATE POLICY "user_roles_select_admin" ON public.user_roles
  FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

-- Only admin can INSERT (e.g. assign role to new user).
DROP POLICY IF EXISTS "user_roles_insert_admin" ON public.user_roles;
CREATE POLICY "user_roles_insert_admin" ON public.user_roles
  FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'));

-- Only admin can UPDATE (change role).
DROP POLICY IF EXISTS "user_roles_update_admin" ON public.user_roles;
CREATE POLICY "user_roles_update_admin" ON public.user_roles
  FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

-- Only admin can DELETE (remove role row).
DROP POLICY IF EXISTS "user_roles_delete_admin" ON public.user_roles;
CREATE POLICY "user_roles_delete_admin" ON public.user_roles
  FOR DELETE USING (public.has_role(auth.uid(), 'admin'));

COMMENT ON TABLE public.user_roles IS 'RBAC role per user. RLS: own SELECT; admin SELECT/INSERT/UPDATE/DELETE.';

-- has_role: when checking for ''admin'', treat super_admin as admin (app isAdmin() aligns with this).
CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_role text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = p_user_id
      AND (role::text = p_role OR (p_role = 'admin' AND role::text = 'super_admin'))
  );
$$;
