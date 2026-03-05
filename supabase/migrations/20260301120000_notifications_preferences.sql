-- Notifications: optional body and action_url; user preference table; allow user to delete own.
-- Safe to run when notifications table already exists (e.g. from Dashboard). Uses DO blocks for idempotency.

-- 1. Add body and action_url to notifications if missing
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'body') THEN
    ALTER TABLE public.notifications ADD COLUMN body text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'action_url') THEN
    ALTER TABLE public.notifications ADD COLUMN action_url text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'created_at') THEN
    ALTER TABLE public.notifications ADD COLUMN created_at timestamptz DEFAULT now();
  END IF;
END $$;

-- 2. User notification preferences (deals, listings, reminders)
CREATE TABLE IF NOT EXISTS public.user_notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  deals_enabled boolean NOT NULL DEFAULT true,
  listings_enabled boolean NOT NULL DEFAULT true,
  reminders_enabled boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_notification_preferences_select_own" ON public.user_notification_preferences;
CREATE POLICY "user_notification_preferences_select_own" ON public.user_notification_preferences
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_notification_preferences_insert_own" ON public.user_notification_preferences;
CREATE POLICY "user_notification_preferences_insert_own" ON public.user_notification_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_notification_preferences_update_own" ON public.user_notification_preferences;
CREATE POLICY "user_notification_preferences_update_own" ON public.user_notification_preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- Admin can read all for support
DROP POLICY IF EXISTS "user_notification_preferences_admin_select" ON public.user_notification_preferences;
CREATE POLICY "user_notification_preferences_admin_select" ON public.user_notification_preferences
  FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

-- 3. Allow users to delete their own notifications (management)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN
    ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
    BEGIN
      CREATE POLICY "notifications_delete_own" ON public.notifications
        FOR DELETE USING (auth.uid() = user_id);
    EXCEPTION WHEN duplicate_object THEN
      NULL; -- policy already exists
    END;
  END IF;
END $$;
