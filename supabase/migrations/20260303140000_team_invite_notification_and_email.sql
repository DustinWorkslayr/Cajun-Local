-- When a user is added to business_managers (team invite), notify them in-app and enqueue a team_invite email.
-- Requires: business_managers, notifications, profiles, email_queue, email_queue_enqueue (4-arg with idempotency_key).

-- Helper: insert a notification for a user (SECURITY DEFINER so trigger can create for invitee despite RLS).
CREATE OR REPLACE FUNCTION public.notify_team_invite(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_action_url text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.notifications (id, user_id, title, body, type, action_url, is_read)
  VALUES (
    gen_random_uuid()::text,
    p_user_id,
    p_title,
    p_body,
    'team_invite',
    p_action_url,
    false
  );
EXCEPTION
  WHEN undefined_table THEN NULL; -- notifications table may not exist in some envs
  WHEN OTHERS THEN NULL;           -- avoid breaking the main insert
END;
$$;

-- Trigger: after insert into business_managers, notify invitee and enqueue email.
CREATE OR REPLACE FUNCTION public.on_business_manager_added_notify()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invitee_email text;
  v_invitee_name text;
  v_business_name text;
  v_inviter_name text;
BEGIN
  -- Invitee profile
  SELECT pr.email, coalesce(trim(pr.display_name), '')
    INTO v_invitee_email, v_invitee_name
    FROM public.profiles pr
    WHERE pr.user_id = NEW.user_id
    LIMIT 1;

  SELECT coalesce(b.name, '') INTO v_business_name
    FROM public.businesses b
    WHERE b.id = NEW.business_id
    LIMIT 1;

  -- Inviter (user who performed the insert)
  SELECT coalesce(trim(pr.display_name), 'A team member')
    INTO v_inviter_name
    FROM public.profiles pr
    WHERE pr.user_id = auth.uid()
    LIMIT 1;

  -- In-app notification for the invitee
  PERFORM public.notify_team_invite(
    NEW.user_id,
    'You were added to ' || v_business_name,
    v_inviter_name || ' added you as a team member. You can now manage this listing from My Listings.',
    '/listings'  -- optional deep link; app can interpret
  );

  -- Email (idempotency so re-add doesn't send duplicate)
  IF v_invitee_email IS NOT NULL AND trim(v_invitee_email) <> '' THEN
    PERFORM public.email_queue_enqueue(
      'team_invite',
      trim(v_invitee_email),
      jsonb_build_object(
        'display_name', coalesce(v_invitee_name, ''),
        'email', trim(v_invitee_email),
        'business_name', v_business_name,
        'inviter_name', v_inviter_name
      ),
      'team_invite:business_managers:' || NEW.business_id::text || ':' || NEW.user_id::text
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_business_manager_added_notify ON public.business_managers;
CREATE TRIGGER trigger_business_manager_added_notify
  AFTER INSERT ON public.business_managers
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_manager_added_notify();

COMMENT ON FUNCTION public.notify_team_invite(uuid, text, text, text) IS 'Insert in-app notification for team invite (SECURITY DEFINER). Used by trigger.';
COMMENT ON FUNCTION public.on_business_manager_added_notify() IS 'On business_managers INSERT: notify invitee in-app and enqueue team_invite email.';

-- Optional: insert team_invite email template if email_templates exists (table may be created by Dashboard).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'email_templates') THEN
    INSERT INTO public.email_templates (name, subject, body)
    VALUES (
      'team_invite',
      'You were added to {{business_name}}',
      'Hi {{display_name}},\n\n{{inviter_name}} added you as a team member to {{business_name}} on Cajun Local. You can now manage this listing from the app under My Listings.\n\n— Cajun Local'
    )
    ON CONFLICT (name) DO NOTHING;
  END IF;
EXCEPTION WHEN OTHERS THEN NULL; -- column names or constraints may differ
END $$;
