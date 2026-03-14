import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/core/subscription/business_tier_service.dart';
import 'package:cajun_local/shared/widgets/business_tier_upgrade_dialog.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.listingId, this.businessTier});

  final String listingId;
  final String? businessTier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = BusinessTierService.fromPlanTier(businessTier);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Overview',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
        ),
        const SizedBox(height: 6),
        Text(
          tier == BusinessTier.free
              ? 'Your listing at a glance. Upgrade for more insights and features.'
              : tier == BusinessTier.localPlus
                  ? 'Track profile views, saves, redemptions, and messages. Your metrics will appear here as customers interact with your listing.'
                  : 'Full analytics for your listing. Profile views, saves, redemptions, and loyalty metrics.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 24),
        // Free: minimal stats + upsell cards
        if (tier == BusinessTier.free) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              const stats = [
                ('Profile views', '—', Icons.visibility_rounded),
                ('Saves', '—', Icons.favorite_rounded),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map(
                      (s) => SizedBox(
                        width: constraints.maxWidth > 400 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                        child: StatCard(label: s.$1, value: s.$2, icon: s.$3),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Get more from your listing',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
          ),
          const SizedBox(height: 12),
          OverviewUpsellCard(
            title: 'Local+',
            tagline: 'Up to 3 deals, scheduling, and form submissions.',
            icon: Icons.workspace_premium_rounded,
            onTap: () => showPlanExplainer(context, 'Local+', _localPlusExplainer),
          ),
          const SizedBox(height: 10),
          OverviewUpsellCard(
            title: 'Local Partner',
            tagline: 'Unlimited deals, Flash & Member-only deals, loyalty programs, more analytics.',
            icon: Icons.star_rounded,
            onTap: () => showPlanExplainer(context, 'Local Partner', _localPartnerExplainer),
          ),
        ],
        // Local+: minimal analytics (4 stat cards)
        if (tier == BusinessTier.localPlus)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 400 ? 2 : 1;
              const stats = [
                ('Profile views', '—', Icons.visibility_rounded),
                ('Saves', '—', Icons.favorite_rounded),
                ('Deal redemptions', '—', Icons.local_offer_rounded),
                ('Messages', '—', Icons.inbox_rounded),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map(
                      (s) => SizedBox(
                        width: crossCount == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                        child: StatCard(label: s.$1, value: s.$2, icon: s.$3),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        // Partner: more analytics (6 stat cards)
        if (tier == BusinessTier.localPartner)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 400 ? 2 : 1;
              const stats = [
                ('Profile views', '—', Icons.visibility_rounded),
                ('Saves', '—', Icons.favorite_rounded),
                ('Deal redemptions', '—', Icons.local_offer_rounded),
                ('Punch card activations', '—', Icons.loyalty_rounded),
                ('Member-only redemptions', '—', Icons.card_membership_rounded),
                ('Messages', '—', Icons.inbox_rounded),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map(
                      (s) => SizedBox(
                        width: crossCount == 2 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                        child: StatCard(label: s.$1, value: s.$2, icon: s.$3),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

const String _localPlusExplainer = 'Local+ gives you up to 3 active deals, the ability to schedule deal start and end dates, '
    'and access to form submissions so you can reply to customers who contact you through your listing. '
    'Upgrade from the More tab or contact support.';

const String _localPartnerExplainer = 'Local Partner unlocks unlimited deals, Flash Deals, Member-only deals, and loyalty (punch card) programs. '
    'You also get full analytics including punch card activations and member-only redemptions. '
    'Upgrade from the More tab or contact support.';

void showPlanExplainer(BuildContext context, String planName, String body) {
  final theme = Theme.of(context);
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.specOffWhite,
      title: Text(
        planName,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
      ),
      content: Text(
        body,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.85), height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Maybe later', style: TextStyle(color: AppTheme.specNavy.withValues(alpha: 0.7))),
        ),
        AppPrimaryButton(
          onPressed: () {
            Navigator.of(context).pop();
            BusinessTierUpgradeDialog.show(context, message: body, title: planName);
          },
          expanded: false,
          label: const Text('View plans'),
        ),
      ],
    ),
  );
}

void showMoreTabPaywall(BuildContext context) {
  final theme = Theme.of(context);
  final nav = AppTheme.specNavy;
  final sub = nav.withValues(alpha: 0.85);
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.specOffWhite,
      title: Row(
        children: [
          Icon(Icons.lock_rounded, color: AppTheme.specGold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unlock the More tab',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: nav),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upgrade to Local+ or Local Partner to access photo carousel, custom links, contact form, and more.',
            style: theme.textTheme.bodyMedium?.copyWith(color: sub, height: 1.4),
          ),
          const SizedBox(height: 20),
          AppSecondaryButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showPlanExplainer(context, 'Local+', _localPlusExplainer);
            },
            icon: const Icon(Icons.workspace_premium_rounded, size: 20),
            label: const Text('Local+'),
          ),
          const SizedBox(height: 10),
          AppPrimaryButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showPlanExplainer(context, 'Local Partner', _localPartnerExplainer);
            },
            expanded: false,
            icon: const Icon(Icons.star_rounded, size: 20),
            label: const Text('Local Partner'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('Not now', style: TextStyle(color: nav.withValues(alpha: 0.7))),
        ),
      ],
    ),
  );
}

class OverviewUpsellCard extends StatelessWidget {
  const OverviewUpsellCard({super.key, required this.title, required this.tagline, required this.icon, required this.onTap});

  final String title;
  final String tagline;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.specNavy, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tagline,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.info_outline_rounded, color: AppTheme.specGold, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.specGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.specNavy, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
          ),
        ],
      ),
    );
  }
}
