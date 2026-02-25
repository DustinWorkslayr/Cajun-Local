-- Allowed parishes for the app (businesses and filters use this list).
-- Admin manages via Admin Parishes screen.
CREATE TABLE IF NOT EXISTS parishes (
  id text PRIMARY KEY,
  name text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_parishes_sort_order ON parishes(sort_order);
ALTER TABLE parishes ENABLE ROW LEVEL SECURITY;
-- Anyone can read (directory filters, business forms, ask-local).
DROP POLICY IF EXISTS "parishes_select_public" ON parishes;
CREATE POLICY "parishes_select_public"
  ON parishes FOR SELECT
  USING (true);
-- Only admin can insert/update/delete.
DROP POLICY IF EXISTS "parishes_insert_admin" ON parishes;
CREATE POLICY "parishes_insert_admin"
  ON parishes FOR INSERT
  WITH CHECK (has_role(auth.uid(), 'admin'));
DROP POLICY IF EXISTS "parishes_update_admin" ON parishes;
CREATE POLICY "parishes_update_admin"
  ON parishes FOR UPDATE
  USING (has_role(auth.uid(), 'admin'));
DROP POLICY IF EXISTS "parishes_delete_admin" ON parishes;
CREATE POLICY "parishes_delete_admin"
  ON parishes FOR DELETE
  USING (has_role(auth.uid(), 'admin'));
-- Seed with current MockData.parishes so existing business_parishes.parish_id remain valid.
INSERT INTO parishes (id, name, sort_order) VALUES
  ('acadia', 'Acadia', 0),
  ('evangeline', 'Evangeline', 1),
  ('iberia', 'Iberia', 2),
  ('jefferson_davis', 'Jefferson Davis', 3),
  ('lafayette', 'Lafayette', 4),
  ('st_landry', 'St. Landry', 5),
  ('st_martin', 'St. Martin', 6),
  ('st_mary', 'St. Mary', 7),
  ('vermilion', 'Vermilion', 8)
ON CONFLICT (id) DO NOTHING;
