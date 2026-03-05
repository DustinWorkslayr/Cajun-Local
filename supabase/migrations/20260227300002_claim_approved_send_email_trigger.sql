-- Claim approved -> enqueue claim_approved email. Requires business_claims (20260227300000) and email_queue (20260221120000).
CREATE OR REPLACE FUNCTION public.on_business_claim_approved_send_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text;
  v_display_name text;
  v_business_name text;
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status <> 'approved') THEN
    SELECT p.email, coalesce(p.display_name, '')
      INTO v_email, v_display_name
      FROM public.profiles p
      WHERE p.user_id = NEW.user_id
      LIMIT 1;
    SELECT b.name INTO v_business_name FROM public.businesses b WHERE b.id = NEW.business_id LIMIT 1;
    PERFORM public.email_queue_enqueue(
      'claim_approved',
      v_email,
      jsonb_build_object(
        'display_name', coalesce(v_display_name, ''),
        'email', coalesce(v_email, ''),
        'business_name', coalesce(v_business_name, '')
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_claim_approved_send_email ON public.business_claims;
CREATE TRIGGER trigger_claim_approved_send_email
  AFTER UPDATE ON public.business_claims
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_claim_approved_send_email();
