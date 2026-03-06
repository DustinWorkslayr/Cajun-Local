-- Notifications for news (blog_posts approved), favorites updates (new deal/event/loyalty at favorited business).
-- Requires: notifications, favorites, user_notification_preferences (with news_enabled, events_enabled), businesses, deals, business_events, punch_card_programs, blog_posts.
-- Run after 20260305120000_notification_preferences_news_events.sql.

-- Helper: notify users who favorited a business and have deals_enabled (or no prefs row = default true). Cap 500.
CREATE OR REPLACE FUNCTION public.notify_favoriters_deals(
  p_business_id uuid,
  p_title text,
  p_body text,
  p_notification_type text,
  p_action_url text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_count int := 0;
  v_max int := 500;
BEGIN
  FOR v_user_id IN
    SELECT f.user_id
    FROM public.favorites f
    LEFT JOIN public.user_notification_preferences pref ON pref.user_id = f.user_id
    WHERE f.business_id = p_business_id
      AND COALESCE(pref.deals_enabled, true) = true
    LIMIT v_max
  LOOP
    BEGIN
      INSERT INTO public.notifications (id, user_id, title, body, type, action_url, is_read)
      VALUES (gen_random_uuid()::text, v_user_id, p_title, p_body, p_notification_type, p_action_url, false);
      v_count := v_count + 1;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
EXCEPTION
  WHEN undefined_table THEN NULL;
  WHEN OTHERS THEN NULL;
END;
$$;

-- Helper: notify users who favorited a business and have events_enabled (or no prefs row = default true). Cap 500.
CREATE OR REPLACE FUNCTION public.notify_favoriters_events(
  p_business_id uuid,
  p_title text,
  p_body text,
  p_notification_type text,
  p_action_url text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_count int := 0;
  v_max int := 500;
BEGIN
  FOR v_user_id IN
    SELECT f.user_id
    FROM public.favorites f
    LEFT JOIN public.user_notification_preferences pref ON pref.user_id = f.user_id
    WHERE f.business_id = p_business_id
      AND COALESCE(pref.events_enabled, true) = true
    LIMIT v_max
  LOOP
    BEGIN
      INSERT INTO public.notifications (id, user_id, title, body, type, action_url, is_read)
      VALUES (gen_random_uuid()::text, v_user_id, p_title, p_body, p_notification_type, p_action_url, false);
      v_count := v_count + 1;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
EXCEPTION
  WHEN undefined_table THEN NULL;
  WHEN OTHERS THEN NULL;
END;
$$;

-- Helper: notify users with news_enabled = true (or no prefs row). Cap 1000.
CREATE OR REPLACE FUNCTION public.notify_news_subscribers(
  p_title text,
  p_body text,
  p_action_url text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_count int := 0;
  v_max int := 1000;
BEGIN
  FOR v_user_id IN
    SELECT pr.user_id
    FROM public.profiles pr
    LEFT JOIN public.user_notification_preferences pref ON pref.user_id = pr.user_id
    WHERE COALESCE(pref.news_enabled, true) = true
    LIMIT v_max
  LOOP
    BEGIN
      INSERT INTO public.notifications (id, user_id, title, body, type, action_url, is_read)
      VALUES (gen_random_uuid()::text, v_user_id, p_title, p_body, 'news', p_action_url, false);
      v_count := v_count + 1;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END LOOP;
EXCEPTION
  WHEN undefined_table THEN NULL;
  WHEN OTHERS THEN NULL;
END;
$$;

-- Trigger: blog_posts status -> approved: notify news subscribers.
CREATE OR REPLACE FUNCTION public.on_blog_post_approved_notify()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_action_url text;
BEGIN
  IF (OLD.status IS DISTINCT FROM 'approved' AND NEW.status = 'approved') AND NEW.published_at IS NOT NULL THEN
    v_action_url := 'app://news/' || COALESCE(NEW.id::text, '');
    PERFORM public.notify_news_subscribers(
      COALESCE(NEW.title, 'New article'),
      COALESCE(NEW.excerpt, 'New article published'),
      v_action_url
    );
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_blog_post_approved_notify ON public.blog_posts;
CREATE TRIGGER trigger_blog_post_approved_notify
  AFTER UPDATE ON public.blog_posts
  FOR EACH ROW
  EXECUTE FUNCTION public.on_blog_post_approved_notify();

-- Trigger: deals status -> approved: notify favoriters (deals_enabled).
CREATE OR REPLACE FUNCTION public.on_deal_approved_notify_favoriters()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_name text;
  v_action_url text;
BEGIN
  IF OLD.status IS DISTINCT FROM 'approved' AND NEW.status = 'approved' THEN
    SELECT coalesce(b.name, '') INTO v_business_name FROM public.businesses b WHERE b.id = NEW.business_id LIMIT 1;
    v_action_url := 'app://listings/' || NEW.business_id::text;
    PERFORM public.notify_favoriters_deals(
      NEW.business_id,
      'New deal at ' || v_business_name,
      COALESCE(NEW.title, 'New promotion'),
      'deal',
      v_action_url
    );
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_deal_approved_notify_favoriters ON public.deals;
CREATE TRIGGER trigger_deal_approved_notify_favoriters
  AFTER UPDATE ON public.deals
  FOR EACH ROW
  EXECUTE FUNCTION public.on_deal_approved_notify_favoriters();

-- Trigger: business_events status -> approved: notify favoriters (events_enabled).
CREATE OR REPLACE FUNCTION public.on_business_event_approved_notify_favoriters()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_name text;
  v_action_url text;
BEGIN
  IF OLD.status IS DISTINCT FROM 'approved' AND NEW.status = 'approved' THEN
    SELECT coalesce(b.name, '') INTO v_business_name FROM public.businesses b WHERE b.id = NEW.business_id LIMIT 1;
    v_action_url := 'app://listings/' || NEW.business_id::text;
    PERFORM public.notify_favoriters_events(
      NEW.business_id,
      'New event at ' || v_business_name,
      COALESCE(NEW.title, 'Upcoming event'),
      'event',
      v_action_url
    );
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_business_event_approved_notify_favoriters ON public.business_events;
CREATE TRIGGER trigger_business_event_approved_notify_favoriters
  AFTER UPDATE ON public.business_events
  FOR EACH ROW
  EXECUTE FUNCTION public.on_business_event_approved_notify_favoriters();

-- Trigger: punch_card_programs INSERT (new loyalty): notify favoriters (deals_enabled), type loyalty.
CREATE OR REPLACE FUNCTION public.on_punch_card_program_insert_notify_favoriters()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_name text;
  v_action_url text;
  v_body text;
BEGIN
  IF NEW.is_active = true THEN
    SELECT coalesce(b.name, '') INTO v_business_name FROM public.businesses b WHERE b.id = NEW.business_id LIMIT 1;
    v_action_url := 'app://listings/' || NEW.business_id::text;
    v_body := COALESCE(NEW.reward_description, 'New punch card available');
    PERFORM public.notify_favoriters_deals(
      NEW.business_id,
      'New loyalty program at ' || v_business_name,
      v_body,
      'loyalty',
      v_action_url
    );
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_punch_card_program_insert_notify_favoriters ON public.punch_card_programs;
CREATE TRIGGER trigger_punch_card_program_insert_notify_favoriters
  AFTER INSERT ON public.punch_card_programs
  FOR EACH ROW
  EXECUTE FUNCTION public.on_punch_card_program_insert_notify_favoriters();

COMMENT ON FUNCTION public.notify_favoriters_deals(uuid, text, text, text, text) IS 'Notify users who favorited business and have deals_enabled (SECURITY DEFINER). Cap 500.';
COMMENT ON FUNCTION public.notify_favoriters_events(uuid, text, text, text, text) IS 'Notify users who favorited business and have events_enabled (SECURITY DEFINER). Cap 500.';
COMMENT ON FUNCTION public.notify_news_subscribers(text, text, text) IS 'Notify users with news_enabled (SECURITY DEFINER). Cap 1000.';
