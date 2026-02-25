-- Email queue for DB-triggered notifications. Triggers enqueue; process-email-queue edge function sends.
-- Table: email_queue (template_name, to_email, variables, status).

CREATE TABLE IF NOT EXISTS public.email_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name text NOT NULL,
  to_email text NOT NULL,
  variables jsonb NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz,
  error_message text
);
CREATE INDEX IF NOT EXISTS idx_email_queue_status ON public.email_queue(status);
CREATE INDEX IF NOT EXISTS idx_email_queue_created_at ON public.email_queue(created_at);
ALTER TABLE public.email_queue ENABLE ROW LEVEL SECURITY;
-- Only service role / backend should read/write; no policies for anon/authenticated so only service role can access.
CREATE POLICY "email_queue_service_role_only"
  ON public.email_queue FOR ALL
  USING (false)
  WITH CHECK (false);
COMMENT ON TABLE public.email_queue IS 'Queue for approval emails. Triggers insert; process-email-queue edge function sends and updates status.';
-- Helper: enqueue one email (only if to_email is non-empty).
CREATE OR REPLACE FUNCTION public.email_queue_enqueue(
  p_template_name text,
  p_to_email text,
  p_variables jsonb DEFAULT '{}'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_to_email IS NOT NULL AND trim(p_to_email) <> '' THEN
    INSERT INTO public.email_queue (template_name, to_email, variables, status)
    VALUES (p_template_name, trim(p_to_email), coalesce(p_variables, '{}'), 'pending');
  END IF;
END;
$$;
-- Trigger: claim approved -> enqueue claim_approved email to claimant.
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
CREATE TRIGGER trigger_claim_approved_send_email
  AFTER UPDATE ON public.business_claims
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_claim_approved_send_email();
-- Trigger: business approved -> enqueue business_approved to creator (created_by).
CREATE OR REPLACE FUNCTION public.on_business_approved_send_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email text;
  v_display_name text;
BEGIN
  IF NEW.status = 'approved' AND (OLD.status IS NULL OR OLD.status <> 'approved') THEN
    IF NEW.created_by IS NOT NULL THEN
      SELECT p.email, coalesce(p.display_name, '')
        INTO v_email, v_display_name
        FROM public.profiles p
        WHERE p.user_id = NEW.created_by
        LIMIT 1;
      PERFORM public.email_queue_enqueue(
        'business_approved',
        coalesce(v_email, ''),
        jsonb_build_object(
          'display_name', coalesce(v_display_name, ''),
          'email', coalesce(v_email, ''),
          'business_name', coalesce(NEW.name, '')
        )
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trigger_business_approved_send_email
  AFTER UPDATE ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_approved_send_email();
-- Trigger: deal approved -> enqueue deal_approved to one business owner (first manager or created_by).
CREATE OR REPLACE FUNCTION public.on_deal_approved_send_email()
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
    SELECT b.name INTO v_business_name FROM public.businesses b WHERE b.id = NEW.business_id LIMIT 1;
    SELECT pr.email, coalesce(pr.display_name, '')
      INTO v_email, v_display_name
      FROM public.business_managers bm
      JOIN public.profiles pr ON pr.user_id = bm.user_id
      WHERE bm.business_id = NEW.business_id
      LIMIT 1;
    IF v_email IS NULL OR trim(v_email) = '' THEN
      SELECT pr.email, coalesce(pr.display_name, '')
        INTO v_email, v_display_name
        FROM public.businesses b
        JOIN public.profiles pr ON pr.user_id = b.created_by
        WHERE b.id = NEW.business_id AND b.created_by IS NOT NULL
        LIMIT 1;
    END IF;
    PERFORM public.email_queue_enqueue(
      'deal_approved',
      coalesce(v_email, ''),
      jsonb_build_object(
        'display_name', coalesce(v_display_name, ''),
        'email', coalesce(v_email, ''),
        'deal_title', coalesce(NEW.title, ''),
        'business_name', coalesce(v_business_name, '')
      )
    );
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trigger_deal_approved_send_email
  AFTER UPDATE ON public.deals
  FOR EACH ROW
  EXECUTE FUNCTION public.on_deal_approved_send_email();
-- Trigger: review approved -> enqueue review_approved to reviewer.
CREATE OR REPLACE FUNCTION public.on_review_approved_send_email()
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
      'review_approved',
      coalesce(v_email, ''),
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
CREATE TRIGGER trigger_review_approved_send_email
  AFTER UPDATE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.on_review_approved_send_email();
-- Trigger: business_image approved -> enqueue image_approved to one business owner.
CREATE OR REPLACE FUNCTION public.on_business_image_approved_send_email()
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
    SELECT b.name INTO v_business_name FROM public.businesses b WHERE b.id = NEW.business_id LIMIT 1;
    SELECT pr.email, coalesce(pr.display_name, '')
      INTO v_email, v_display_name
      FROM public.business_managers bm
      JOIN public.profiles pr ON pr.user_id = bm.user_id
      WHERE bm.business_id = NEW.business_id
      LIMIT 1;
    IF v_email IS NULL OR trim(v_email) = '' THEN
      SELECT pr.email, coalesce(pr.display_name, '')
        INTO v_email, v_display_name
        FROM public.businesses b
        JOIN public.profiles pr ON pr.user_id = b.created_by
        WHERE b.id = NEW.business_id AND b.created_by IS NOT NULL
        LIMIT 1;
    END IF;
    PERFORM public.email_queue_enqueue(
      'image_approved',
      coalesce(v_email, ''),
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
CREATE TRIGGER trigger_business_image_approved_send_email
  AFTER UPDATE ON public.business_images
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_image_approved_send_email();
