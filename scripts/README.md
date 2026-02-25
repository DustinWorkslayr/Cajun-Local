# Scripts

## Seed database (fake data for testing)

Populates the Supabase database with categories, businesses, deals, blog posts, and related rows so you can test the app with realistic data.

### Option 1: SQL seed (Supabase CLI)

From the project root:

```bash
supabase db reset   # resets DB, runs migrations, then runs seed
# or
supabase db seed    # runs only supabase/seed.sql on the current DB
```

Requires [Supabase CLI](https://supabase.com/docs/guides/cli) and a linked or local project.

### Option 2: Dart script (service role)

Uses the Supabase client with the **service role** key so RLS is bypassed. Good for hosted projects or when you want to re-run without resetting.

**Required environment variables:**

- `SUPABASE_URL` — your project URL (e.g. `https://xxxx.supabase.co`)
- `SUPABASE_SERVICE_ROLE_KEY` — service role key from Project Settings → API (never commit this)

**Run:**

```bash
dart run scripts/seed_database.dart
```

Re-running is safe: the script uses upsert where possible so existing rows are updated instead of causing duplicate-key errors.
