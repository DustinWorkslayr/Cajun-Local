-- Add RevenueCat product ID to ad packages (IAP for ads; Stripe no longer used for ad payment).
-- Pricing-and-ads-cheatsheet §2.5: ad_packages. Admin sets revenuecat_product_id when package is paid via IAP.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'ad_packages') THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'ad_packages' AND column_name = 'revenuecat_product_id'
    ) THEN
      ALTER TABLE public.ad_packages ADD COLUMN revenuecat_product_id text;
    END IF;
  END IF;
END $$;
