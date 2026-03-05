-- Blog posts can be targeted to specific parishes or all parishes.
-- parish_ids: NULL or empty = show to all parishes; otherwise array of parish ids.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'blog_posts') THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'blog_posts' AND column_name = 'parish_ids'
    ) THEN
      ALTER TABLE public.blog_posts ADD COLUMN parish_ids text[] DEFAULT NULL;
      COMMENT ON COLUMN public.blog_posts.parish_ids IS 'When NULL or empty, post is shown to all parishes. Otherwise only to users whose preferred parish is in this array.';
    END IF;
  END IF;
END $$;
