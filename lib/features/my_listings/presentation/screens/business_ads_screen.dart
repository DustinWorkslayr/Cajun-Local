import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/ad_package.dart';
import 'package:my_app/core/data/models/business_ad.dart';
import 'package:my_app/core/data/repositories/ad_packages_repository.dart';
import 'package:my_app/core/data/repositories/business_ads_repository.dart';
import 'package:my_app/core/data/services/app_storage_service.dart';
import 'package:my_app/core/stripe/stripe_checkout_service.dart';
import 'package:my_app/core/stripe/stripe_config.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:url_launcher/url_launcher.dart';

/// For a single business: list its ads and start "Buy ad" flow (package -> form -> checkout).
class BusinessAdsScreen extends StatefulWidget {
  const BusinessAdsScreen({super.key, required this.businessId});

  final String businessId;

  @override
  State<BusinessAdsScreen> createState() => _BusinessAdsScreenState();
}

class _BusinessAdsScreenState extends State<BusinessAdsScreen> {
  late Future<List<BusinessAd>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _adsFuture = BusinessAdsRepository().listByBusiness(widget.businessId);
  }

  void _refresh() {
    setState(() {
      _adsFuture =
          BusinessAdsRepository().listByBusiness(widget.businessId);
    });
  }

  Future<void> _buyAd(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _CreateAdScreen(
          businessId: widget.businessId,
          onCreated: () {},
        ),
      ),
    );
    if (result == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
        title: Text(
          'Advertising',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: FutureBuilder<List<BusinessAd>>(
        future: _adsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            );
          }
          final list = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              Text(
                'Promote your business with sponsored placements.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.campaign_rounded,
                            size: 64, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'No ads yet. Buy an ad package to get started.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...list.map((ad) => _AdCard(
                      ad: ad,
                      onTap: () => _AdDetailSlideOut.show(context, ad: ad),
                    )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buyAd(context),
        backgroundColor: AppTheme.specNavy,
        foregroundColor: AppTheme.specWhite,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buy ad'),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad, this.onTap});

  final BusinessAd ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      ad.imageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(context),
                    ),
                  )
                else
                  _placeholder(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.headline?.isNotEmpty == true
                            ? ad.headline!
                            : 'Ad',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.specNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ad.packageName ?? 'Package'} · ${BusinessAd.statusLabel(ad.status)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.7),
                        ),
                      ),
                      if (ad.impressions > 0 || ad.clicks > 0)
                        Text(
                          'Impressions: ${ad.impressions} · Clicks: ${ad.clicks}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specNavy.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(ad.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    BusinessAd.statusLabel(ad.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _statusColor(ad.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.specGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.campaign_rounded,
          color: AppTheme.specNavy, size: 28),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'rejected':
      case 'expired':
        return AppTheme.specRed;
      case 'pending_payment':
      case 'pending_approval':
        return AppTheme.specGold;
      default:
        return AppTheme.specNavy;
    }
  }
}

/// Slide-out panel: ad details, analytics, remaining time with progress bar.
class _AdDetailSlideOut extends StatelessWidget {
  const _AdDetailSlideOut({required this.ad, required this.onClose});

  final BusinessAd ad;
  final VoidCallback onClose;

  static void show(BuildContext context, {required BusinessAd ad}) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionBuilder: (ctx, a1, a2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
      pageBuilder: (ctx, _, _) => Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppTheme.specOffWhite,
            elevation: 24,
            child: SizedBox(
              width: MediaQuery.sizeOf(ctx).width * 0.9,
              child: _AdDetailSlideOut(ad: ad, onClose: () => Navigator.of(ctx).pop()),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final now = DateTime.now();
    final end = ad.endDate;
    final start = ad.startDate ?? ad.createdAt;
    int? daysTotal;
    int? daysLeft;
    double progress = 0;
    if (start != null && end != null) {
      daysTotal = end.difference(start).inDays;
      if (daysTotal > 0) {
        if (now.isAfter(end)) {
          daysLeft = 0;
          progress = 0; // remaining fraction: 0 = no time left
        } else {
          daysLeft = end.difference(now).inDays;
          final elapsed = now.difference(start).inDays;
          final elapsedFraction = (elapsed / daysTotal).clamp(0.0, 1.0);
          progress = 1.0 - elapsedFraction; // remaining: 1 = full time left, 0 = ended
        }
      }
    }
    final ctr = ad.impressions > 0
        ? (ad.clicks / ad.impressions * 100).toStringAsFixed(1)
        : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ad details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: nav,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      ad.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _detailPlaceholder(),
                    ),
                  )
                else
                  _detailPlaceholder(),
                const SizedBox(height: 16),
                Text(
                  ad.headline?.isNotEmpty == true ? ad.headline! : 'Ad',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${ad.packageName ?? 'Package'} · ${ad.placement != null ? AdPackage.placementLabel(ad.placement!) : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(ad.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    BusinessAd.statusLabel(ad.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _statusColor(ad.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (daysLeft != null || daysTotal != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Time remaining',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: nav,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: nav.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  daysLeft != null && daysLeft > 0
                                      ? AppTheme.specGold
                                      : nav.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              daysLeft != null
                                  ? (daysLeft > 0
                                      ? '$daysLeft of $daysTotal days left'
                                      : 'Ad ended')
                                  : (daysTotal != null ? '$daysTotal days total' : '—'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        daysLeft != null
                            ? (daysLeft > 0 ? '$daysLeft days left' : 'Ended')
                            : (daysTotal != null ? '$daysTotal days' : '—'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: nav,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Analytics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Impressions',
                        value: '${ad.impressions}',
                        theme: theme,
                        nav: nav,
                        sub: sub,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatChip(
                        label: 'Clicks',
                        value: '${ad.clicks}',
                        theme: theme,
                        nav: nav,
                        sub: sub,
                      ),
                    ),
                  ],
                ),
                if (ctr != null) ...[
                  const SizedBox(height: 10),
                  _StatChip(
                    label: 'Click-through rate',
                    value: '$ctr%',
                    theme: theme,
                    nav: nav,
                    sub: sub,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailPlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.specGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.campaign_rounded, color: AppTheme.specNavy, size: 48),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'rejected':
      case 'expired':
        return AppTheme.specRed;
      case 'pending_payment':
      case 'pending_approval':
        return AppTheme.specGold;
      default:
        return AppTheme.specNavy;
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.theme,
    required this.nav,
    required this.sub,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final Color nav;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nav.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: sub),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: nav,
            ),
          ),
        ],
      ),
    );
  }
}

/// Upsell block for Buy ad page: what ads are, how they work, why advertise.
class _BuyAdUpsellBlock extends StatelessWidget {
  const _BuyAdUpsellBlock({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.campaign_rounded, color: nav, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get in front of more locals',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nav,
                      ),
                    ),
                    Text(
                      'Sponsored placements in Explore and Deals',
                      style: theme.textTheme.bodySmall?.copyWith(color: sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Sponsored placements put your business where your neighbors are looking. Choose a package, add your creative, and we\'ll run it in the app. When someone taps your ad, they go straight to your listing—no leaving the app.',
            style: theme.textTheme.bodySmall?.copyWith(color: nav, height: 1.45),
          ),
          const SizedBox(height: 14),
          Text(
            'How it works',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: nav,
            ),
          ),
          const SizedBox(height: 6),
          _UpsellStep(theme: theme, step: 1, text: 'Pick a package that fits your goals.', sub: sub),
          _UpsellStep(theme: theme, step: 2, text: 'Add a headline and image (we review for quality).', sub: sub),
          _UpsellStep(theme: theme, step: 3, text: 'Your ad runs in the app; taps open your listing.', sub: sub),
          const SizedBox(height: 12),
          Text(
            'Why advertise here',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: nav,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.people_rounded, size: 16, color: AppTheme.specGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reach members who support local—high intent.',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub, height: 1.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.trending_up_rounded, size: 16, color: AppTheme.specGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'See impressions and clicks so you can optimize.',
                  style: theme.textTheme.bodySmall?.copyWith(color: sub, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpsellStep extends StatelessWidget {
  const _UpsellStep({
    required this.theme,
    required this.step,
    required this.text,
    required this.sub,
  });

  final ThemeData theme;
  final int step;
  final String text;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.specGold, width: 1),
            ),
            child: Center(
              child: Text(
                '$step',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.specNavy,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: sub, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flow: select package -> form (headline, image) -> create draft -> Stripe checkout. Taps open listing in-app.
class _CreateAdScreen extends StatefulWidget {
  const _CreateAdScreen({
    required this.businessId,
    required this.onCreated,
  });

  final String businessId;
  final VoidCallback onCreated;

  @override
  State<_CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<_CreateAdScreen> {
  List<AdPackage> _packages = [];
  bool _loadingPackages = true;
  AdPackage? _selectedPackage;
  final _headlineController = TextEditingController();
  String? _imageUrl;
  bool _uploading = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _headlineController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    final list = await AdPackagesRepository().list(activeOnly: true);
    if (mounted) {
      setState(() {
        _packages = list;
        _loadingPackages = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final path = result.files.single.path;
    if (path == null) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) return;
    setState(() => _uploading = true);
    try {
      final ext = result.files.single.extension ?? 'jpg';
      final url = await AppStorageService().uploadAdImage(
        businessId: widget.businessId,
        bytes: bytes,
        extension: ext,
      );
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _submit() async {
    final pkg = _selectedPackage;
    if (pkg == null) {
      setState(() => _error = 'Select a package');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final repo = BusinessAdsRepository();
      final ad = await repo.insertDraft(
        businessId: widget.businessId,
        packageId: pkg.id,
        headline: _headlineController.text.trim().isEmpty
            ? null
            : _headlineController.text.trim(),
        imageUrl: _imageUrl,
        targetUrl: null,
      );
      if (ad == null) throw Exception('Failed to create ad');
      if (pkg.stripePriceId != null && pkg.stripePriceId!.isNotEmpty) {
        final checkout = StripeCheckoutService();
        final base = StripeConfig.returnBaseUrl;
        final suffix = base.endsWith('/') ? '' : '/';
        final successUrl = base.isEmpty ? null : '$base${suffix}my-listings?checkout=success';
        final cancelUrl = base.isEmpty ? null : '$base${suffix}my-listings?checkout=canceled';
        final url = await checkout.createCheckoutSession(
          priceId: pkg.stripePriceId!,
          mode: 'payment',
          successUrl: successUrl,
          cancelUrl: cancelUrl,
          metadata: {
            'type': 'advertisement',
            'business_id': widget.businessId,
            'reference_id': ad.id,
          },
        );
        if (mounted) {
          setState(() => _submitting = false);
          Navigator.of(context).pop(true);
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      } else {
        if (mounted) {
          setState(() => _submitting = false);
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ad created as draft. Payment not configured for this package.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
        title: Text(
          'Buy ad',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: _loadingPackages
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BuyAdUpsellBlock(theme: theme),
                  const SizedBox(height: 24),
                  Text(
                    'Select a package',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_packages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No ad packages available. Contact support.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  else
                    ..._packages.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: _selectedPackage?.id == p.id
                                ? AppTheme.specGold.withValues(alpha: 0.25)
                                : AppTheme.specWhite,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedPackage = p),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.campaign_rounded,
                                          color: AppTheme.specNavy,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: theme.textTheme.titleSmall
                                                    ?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.specNavy),
                                              ),
                                              Text(
                                                '\$${p.price.toStringAsFixed(0)} · ${p.durationDays} days · ${AdPackage.placementLabel(p.placement)}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: AppTheme.specNavy
                                                            .withValues(alpha: 0.7)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_selectedPackage?.id == p.id)
                                          const Icon(Icons.check_circle_rounded,
                                              color: AppTheme.specNavy),
                                      ],
                                    ),
                                    if (_selectedPackage?.id == p.id) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.specOffWhite,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.1)),
                                        ),
                                        child: Text(
                                          AdPackage.placementDescription(p.placement),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppTheme.specNavy.withValues(alpha: 0.85),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                  const SizedBox(height: 24),
                  Text(
                    'Ad details (optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'When someone taps your ad, they\'re taken to your listing inside the app—they stay in Cajun Local.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _headlineController,
                    decoration: const InputDecoration(
                      labelText: 'Headline',
                      hintText: 'Short headline for your ad',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.specNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image_rounded,
                              color: AppTheme.specNavy.withValues(alpha: 0.5)),
                        ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _uploading ? null : _pickImage,
                        icon: _uploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_rounded, size: 20),
                        label: Text(_imageUrl != null ? 'Change image' : 'Upload image'),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.specRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppSecondaryButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create ad & pay'),
                  ),
                ],
              ),
            ),
    );
  }
}
