-- Scalability: indexes for hot paths and email_queue idempotency.
-- See plan: scalability_and_best-practices_repairs.

-- businesses: directory-sync uses status + updated_at + order(updated_at)
CREATE INDEX IF NOT EXISTS idx_businesses_status_updated_at
  ON public.businesses (status, updated_at);

-- businesses: public-search filters by parish
CREATE INDEX IF NOT EXISTS idx_businesses_parish
  ON public.businesses (parish)
  WHERE status = 'approved';

-- blog_posts: blog-sync uses status + updated_at and order(published_at)
CREATE INDEX IF NOT EXISTS idx_blog_posts_status_updated_at
  ON public.blog_posts (status, updated_at);

CREATE INDEX IF NOT EXISTS idx_blog_posts_status_published_at
  ON public.blog_posts (status, published_at);

-- email_queue: process-email-queue selects pending order by created_at limit N
CREATE INDEX IF NOT EXISTS idx_email_queue_status_created_at
  ON public.email_queue (status, created_at);

-- email_queue: optional idempotency key to avoid duplicate emails from triggers/retries
ALTER TABLE public.email_queue
  ADD COLUMN IF NOT EXISTS idempotency_key text;

CREATE UNIQUE INDEX IF NOT EXISTS idx_email_queue_idempotency_key
  ON public.email_queue (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

COMMENT ON COLUMN public.email_queue.idempotency_key IS 'Optional key for deduplication; unique when set (e.g. template_name:entity_type:entity_id).';

-- Enqueue helper: accept optional idempotency key; skip insert if key already exists (pending)
CREATE OR REPLACE FUNCTION public.email_queue_enqueue(
  p_template_name text,
  p_to_email text,
  p_variables jsonb DEFAULT '{}',
  p_idempotency_key text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_to_email IS NULL OR trim(p_to_email) = '' THEN
    RETURN;
  END IF;
  IF p_idempotency_key IS NOT NULL AND trim(p_idempotency_key) <> '' THEN
    IF EXISTS (
      SELECT 1 FROM public.email_queue
      WHERE idempotency_key = trim(p_idempotency_key)
      AND status = 'pending'
    ) THEN
      RETURN; -- already enqueued
    END IF;
  END IF;
  INSERT INTO public.email_queue (template_name, to_email, variables, status, idempotency_key)
  VALUES (p_template_name, trim(p_to_email), coalesce(p_variables, '{}'), 'pending', NULLIF(trim(p_idempotency_key), ''));
END;
$$;
