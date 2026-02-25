# my_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Email queue (cron)

To send queued emails (e.g. approval notifications), either use the admin **Process email queue** button in the app or run the `process-email-queue` edge function on a schedule. For cron: POST to `{SUPABASE_URL}/functions/v1/process-email-queue` every 1–5 minutes (no Authorization header required). Admins can also trigger it manually from the dashboard.

## Database seed (testing)

To add fake data for testing: use **SQL seed** (`supabase db reset` or `supabase db seed`) or the **Dart script** — run `dart run scripts/seed_database.dart` with `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` set. See [scripts/README.md](scripts/README.md).
