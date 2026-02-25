-- Add admin note and optional audit fields for form submissions (manager/admin reply or internal note).
ALTER TABLE public.form_submissions
  ADD COLUMN IF NOT EXISTS admin_note text,
  ADD COLUMN IF NOT EXISTS replied_at timestamptz,
  ADD COLUMN IF NOT EXISTS replied_by uuid REFERENCES auth.users(id);

COMMENT ON COLUMN public.form_submissions.admin_note IS 'Internal note or reply text; visible to business manager and admin.';
COMMENT ON COLUMN public.form_submissions.replied_at IS 'When admin_note was set (audit).';
COMMENT ON COLUMN public.form_submissions.replied_by IS 'User who set admin_note (audit).';
