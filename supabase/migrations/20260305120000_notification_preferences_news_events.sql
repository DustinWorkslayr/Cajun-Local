-- Add news_enabled and events_enabled to user_notification_preferences.
-- Defaults: true so existing users get news and events notifications.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'user_notification_preferences' AND column_name = 'news_enabled') THEN
    ALTER TABLE public.user_notification_preferences ADD COLUMN news_enabled boolean NOT NULL DEFAULT true;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'user_notification_preferences' AND column_name = 'events_enabled') THEN
    ALTER TABLE public.user_notification_preferences ADD COLUMN events_enabled boolean NOT NULL DEFAULT true;
  END IF;
END $$;
