-- business_managers: RLS so managers can list/add/remove team access for their business.
-- RPCs: list_business_managers (managers see who has access), lookup_user_id_by_email (add by email).

ALTER TABLE public.business_managers ENABLE ROW LEVEL SECURITY;

-- SELECT: admin or manager of this business
DROP POLICY IF EXISTS "business_managers_select_admin_or_manager" ON public.business_managers;
CREATE POLICY "business_managers_select_admin_or_manager"
  ON public.business_managers FOR SELECT
  USING (
    public.has_role(auth.uid(), 'admin')
    OR public.is_business_manager(auth.uid(), business_id)
  );

-- INSERT: admin or manager of this business; cannot add self (prevents duplicate)
DROP POLICY IF EXISTS "business_managers_insert_admin_or_manager" ON public.business_managers;
CREATE POLICY "business_managers_insert_admin_or_manager"
  ON public.business_managers FOR INSERT
  WITH CHECK (
    (public.has_role(auth.uid(), 'admin') OR public.is_business_manager(auth.uid(), business_id))
    AND user_id != auth.uid()
  );

-- DELETE: admin or manager of this business (can remove any manager including self if desired)
DROP POLICY IF EXISTS "business_managers_delete_admin_or_manager" ON public.business_managers;
CREATE POLICY "business_managers_delete_admin_or_manager"
  ON public.business_managers FOR DELETE
  USING (
    public.has_role(auth.uid(), 'admin')
    OR public.is_business_manager(auth.uid(), business_id)
  );

-- List managers for a business with profile display_name and email. Callable by admin or manager of that business.
CREATE OR REPLACE FUNCTION public.list_business_managers(p_business_id uuid)
RETURNS TABLE(user_id uuid, role text, display_name text, email text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT bm.user_id, bm.role,
         pr.display_name,
         pr.email
  FROM public.business_managers bm
  LEFT JOIN public.profiles pr ON pr.user_id = bm.user_id
  WHERE bm.business_id = p_business_id
    AND (public.has_role(auth.uid(), 'admin') OR public.is_business_manager(auth.uid(), p_business_id));
$$;

-- Lookup user_id by email so a manager can add someone by email. Only callable by admin or manager of the business.
CREATE OR REPLACE FUNCTION public.lookup_user_id_by_email(p_business_id uuid, p_email text)
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  DECLARE
    v_user_id uuid;
  BEGIN
    IF NOT (public.has_role(auth.uid(), 'admin') OR public.is_business_manager(auth.uid(), p_business_id)) THEN
      RETURN NULL;
    END IF;
    SELECT pr.user_id INTO v_user_id
    FROM public.profiles pr
    WHERE lower(trim(pr.email)) = lower(trim(p_email))
    LIMIT 1;
    RETURN v_user_id;
  END;
$$;

COMMENT ON FUNCTION public.list_business_managers(uuid) IS 'List managers for a business with profile info. Callable by admin or business manager.';
COMMENT ON FUNCTION public.lookup_user_id_by_email(uuid, text) IS 'Resolve user_id by email for adding team access. Callable by admin or business manager.';
