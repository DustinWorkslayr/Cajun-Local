-- Allow admin to UPDATE and INSERT user_notification_preferences (for support/compliance).
-- Existing: own SELECT/INSERT/UPDATE; admin SELECT.

DROP POLICY IF EXISTS "user_notification_preferences_admin_update" ON public.user_notification_preferences;
CREATE POLICY "user_notification_preferences_admin_update" ON public.user_notification_preferences
  FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "user_notification_preferences_admin_insert" ON public.user_notification_preferences;
CREATE POLICY "user_notification_preferences_admin_insert" ON public.user_notification_preferences
  FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'));
