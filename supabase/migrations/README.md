# Migrations

Migrations run in **filename order** (lexicographic). Apply with:

- **Local (fresh DB):** `supabase db reset`
- **Local (apply new only):** `supabase db push`
- **Remote:** `supabase db push` (with linked project) or run SQL in Dashboard.

## Order and dependencies

| Migration | Purpose | Depends on |
|-----------|---------|------------|
| `20260220000000_create_core_listing_tables.sql` | business_categories, subcategories, businesses | — |
| `20260220050000_rbac_tables_and_functions.sql` | business_managers, user_roles, has_role(), is_business_manager() | businesses |
| `20260221000000_add_business_parishes.sql` | business_parishes table + RLS | businesses, has_role, is_business_manager |
| `20260221100000_claim_approved_trigger.sql` | Trigger on business_claims → business_managers, user_roles | business_claims, business_managers, user_roles |
| `20260221120000_email_queue_and_triggers.sql` | email_queue table + approval email triggers | businesses, profiles, business_claims, deals, reviews, business_images |
| `20260221150000_businesses_rls_insert_own.sql` | INSERT policy + status default | businesses |
| `20260221160000_favorites_count_rpc.sql` | get_favorites_count() | (favorites / businesses) |
| `20260221200000_businesses_logo_and_banner_url.sql` | logo_url, banner_url on businesses | businesses |
| `20260221210000_punch_card_redemption_rpcs.sql` | redeem_punch_card, list_punch_card_enrollments | is_business_manager, user_punch_cards, punch_card_programs, profiles |
| `20260222000000_businesses_rls_insert_fix.sql` | RLS + INSERT policy (idempotent fix) | businesses |
| `20260222100000_parishes_table.sql` | parishes table + RLS + seed | has_role |
| `20260223100000_add_slugs_to_tables.sql` | slug columns + triggers (categories, subcategories, businesses, parishes, blog_posts) | business_categories, subcategories, businesses, parishes, blog_posts |
| `20260224100000_add_bucket_to_business_categories.sql` | bucket column on business_categories | business_categories |
| `20260225100000_businesses_delete_admin.sql` | DELETE policy for admin on businesses | businesses, has_role |
| `20260225110000_form_submissions_admin_note.sql` | admin_note, replied_at, replied_by on form_submissions | form_submissions |
| `20260226100000_fix_businesses_slug_trigger.sql` | set_businesses_slug() fix for null name | businesses, slug helpers |
| `20260227100000_businesses_select_own_for_returning.sql` | SELECT policy so insert+returning id works | businesses |

**Note:** Some migrations expect tables (e.g. business_claims, profiles, deals, blog_posts, form_submissions) that may be created outside this set (e.g. Dashboard or another repo). Seed data in `../seed.sql` assumes the core tables and parishes exist.
