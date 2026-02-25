import 'package:flutter/material.dart';
import 'package:my_app/core/auth/auth_repository.dart';
import 'package:my_app/core/data/models/business_ad.dart';
import 'package:my_app/core/data/models/payment_history_entry.dart';
import 'package:my_app/core/data/models/user_plan.dart';
import 'package:my_app/core/data/repositories/business_ads_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/business_subscriptions_repository.dart';
import 'package:my_app/core/data/repositories/payment_history_repository.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_business_ads_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_business_detail_screen.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: view payment history (read-only). Optional filters. Shows business or user name; tap to view detail.
class AdminPaymentHistoryScreen extends StatefulWidget {
  const AdminPaymentHistoryScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminPaymentHistoryScreen> createState() =>
      _AdminPaymentHistoryScreenState();
}

class _AdminPaymentHistoryScreenState extends State<AdminPaymentHistoryScreen> {
  String? _typeFilter;

  Future<({
    List<PaymentHistoryEntry> list,
    Map<String, String> businessNames,
    Map<String, String> userNames,
  })> _loadPaymentsWithNames() async {
    final repo = PaymentHistoryRepository();
    final list = await repo.list(paymentType: _typeFilter);
    final businessIds = list.map((e) => e.businessId).whereType<String>().toSet();
    final userIds = list.map((e) => e.userId).whereType<String>().toSet();
    final businessRepo = BusinessRepository();
    final authRepo = AuthRepository();
    final businessNames = <String, String>{};
    final userNames = <String, String>{};
    for (final id in businessIds) {
      final b = await businessRepo.getByIdForAdmin(id);
      if (b != null) businessNames[id] = b.name;
    }
    for (final id in userIds) {
      final p = await authRepo.getProfileForAdmin(id);
      if (p != null) {
        userNames[id] = p.displayName?.trim().isNotEmpty == true
            ? p.displayName!
            : (p.email ?? id.substring(0, 8));
      }
    }
    return (list: list, businessNames: businessNames, userNames: userNames);
  }

  String _displayName(
    PaymentHistoryEntry e,
    Map<String, String> businessNames,
    Map<String, String> userNames,
  ) {
    if (e.businessId != null && businessNames[e.businessId] != null) {
      return businessNames[e.businessId]!;
    }
    if (e.userId != null && userNames[e.userId] != null) {
      return userNames[e.userId]!;
    }
    if (e.businessId != null) return 'Business ${e.businessId!.substring(0, 8)}…';
    if (e.userId != null) return 'User ${e.userId!.substring(0, 8)}…';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = ['business_subscription', 'user_subscription', 'advertisement'];

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Payment history',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.specNavy),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _typeFilter == null,
                  onSelected: (_) => setState(() => _typeFilter = null),
                  selectedColor: AppTheme.specGold.withValues(alpha: 0.4),
                ),
                ...types.map((t) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FilterChip(
                        label: Text(PaymentHistoryEntry.paymentTypeLabel(t)),
                        selected: _typeFilter == t,
                        onSelected: (_) => setState(() => _typeFilter = t),
                        selectedColor: AppTheme.specGold.withValues(alpha: 0.4),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<({
        List<PaymentHistoryEntry> list,
        Map<String, String> businessNames,
        Map<String, String> userNames,
      })>(
        future: _loadPaymentsWithNames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.specNavy),
            );
          }
          final data = snapshot.data;
          if (data == null || data.list.isEmpty) {
            final typeFilter = _typeFilter;
            return Center(
              child: Text(
                'No payments${typeFilter != null ? ' of type ${PaymentHistoryEntry.paymentTypeLabel(typeFilter)}' : ''}.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.8),
                ),
              ),
            );
          }
          final list = data.list;
          final businessNames = data.businessNames;
          final userNames = data.userNames;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final e = list[index];
              final dateStr = e.createdAt != null
                  ? '${e.createdAt!.toIso8601String().substring(0, 10)} ${e.createdAt!.toIso8601String().substring(11, 19)}'
                  : '—';
              final displayName = _displayName(e, businessNames, userNames);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminListCard(
                  title: displayName,
                  subtitle: '\$${e.amount.toStringAsFixed(2)} ${e.currency.toUpperCase()} · '
                      '${PaymentHistoryEntry.paymentTypeLabel(e.paymentType)} · $dateStr',
                  badges: [
                    AdminBadgeData(e.status,
                        color: e.status == 'succeeded'
                            ? null
                            : e.status == 'failed'
                                ? AppTheme.specRed
                                : null),
                  ],
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.specGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.specNavy, size: 26),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.specNavy,
                    size: 24,
                  ),
                  onTap: () => _PaymentDetailSlideOut.show(
                    context,
                    entry: e,
                    businessName: e.businessId != null ? businessNames[e.businessId] : null,
                    userName: e.userId != null ? userNames[e.userId] : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Slide-out: payment detail with intuitive theme and resolved relational data.
class _PaymentDetailSlideOut extends StatefulWidget {
  const _PaymentDetailSlideOut({
    required this.entry,
    required this.onClose,
    this.businessName,
    this.userName,
  });

  final PaymentHistoryEntry entry;
  final VoidCallback onClose;
  final String? businessName;
  final String? userName;

  static void show(
    BuildContext context, {
    required PaymentHistoryEntry entry,
    String? businessName,
    String? userName,
  }) {
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
      pageBuilder: (ctx, _, _) {
        final panelWidth = (MediaQuery.sizeOf(ctx).width * 0.92).clamp(0.0, 420.0);
        return Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: AppTheme.specOffWhite,
              elevation: 24,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: panelWidth,
                  maxWidth: panelWidth,
                  minHeight: 0,
                  maxHeight: double.infinity,
                ),
                child: _PaymentDetailSlideOut(
                  entry: entry,
                  businessName: businessName,
                  userName: userName,
                  onClose: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<_PaymentDetailSlideOut> createState() => _PaymentDetailSlideOutState();
}

class _PaymentDetailSlideOutState extends State<_PaymentDetailSlideOut> {
  BusinessAd? _relatedAd;
  String? _businessPlanName;
  UserPlan? _userPlan;
  bool _relatedLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    final e = widget.entry;
    BusinessAd? ad;
    String? planName;
    UserPlan? plan;
    if (e.paymentType == 'advertisement' && e.referenceId != null && e.referenceId!.isNotEmpty) {
      ad = await BusinessAdsRepository().getById(e.referenceId!);
    } else if (e.paymentType == 'business_subscription' && e.businessId != null) {
      final sub = await BusinessSubscriptionsRepository().getByBusinessId(e.businessId!);
      if (sub != null) planName = sub.planName;
    } else if (e.paymentType == 'user_subscription' && e.referenceId != null && e.referenceId!.isNotEmpty) {
      plan = await UserPlansRepository().getById(e.referenceId!);
    }
    if (!mounted) return;
    setState(() {
      _relatedAd = ad;
      _businessPlanName = planName;
      _userPlan = plan;
      _relatedLoaded = true;
    });
  }

  String _customerName() {
    final e = widget.entry;
    if (widget.businessName != null && widget.businessName!.isNotEmpty) return widget.businessName!;
    if (widget.userName != null && widget.userName!.isNotEmpty) return widget.userName!;
    if (e.businessId != null) return 'Business ${e.businessId!.substring(0, 8)}…';
    if (e.userId != null) return 'User ${e.userId!.substring(0, 8)}…';
    return '—';
  }

  String _lineItemDescription() {
    final e = widget.entry;
    if (e.paymentType == 'business_subscription' && _businessPlanName != null && _businessPlanName!.isNotEmpty) {
      return '${PaymentHistoryEntry.paymentTypeLabel(e.paymentType)} · $_businessPlanName';
    }
    if (e.paymentType == 'user_subscription' && _userPlan != null) {
      return '${PaymentHistoryEntry.paymentTypeLabel(e.paymentType)} · ${_userPlan!.name}';
    }
    if (e.paymentType == 'advertisement' && _relatedAd != null) {
      final headline = _relatedAd!.headline?.trim().isNotEmpty == true ? _relatedAd!.headline! : 'Ad';
      return '${PaymentHistoryEntry.paymentTypeLabel(e.paymentType)} · $headline';
    }
    return PaymentHistoryEntry.paymentTypeLabel(e.paymentType);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final e = widget.entry;
    final dateStr =
        (e.createdAt?.toIso8601String())?.substring(0, 10) ?? '—';
    final timeStr =
        (e.createdAt?.toIso8601String())?.substring(11, 19);
    final statusColor = e.status == 'succeeded'
        ? Colors.green.shade300
        : e.status == 'failed'
            ? Colors.red.shade300
            : AppTheme.specWhite.withValues(alpha: 0.9);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Payment receipt',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: nav,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
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
                Container(
                  decoration: BoxDecoration(
                color: AppTheme.specWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: nav.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Invoice-style header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    decoration: BoxDecoration(
                      color: AppTheme.specNavy,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PAYMENT RECEIPT',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppTheme.specWhite,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _invoiceRow(theme, 'Payment ID', e.id.isNotEmpty ? e.id : '—', isHeader: true),
                        const SizedBox(height: 6),
                        _invoiceRow(theme, 'Date', dateStr, isHeader: true),
                        if (timeStr != null) ...[
                          const SizedBox(height: 2),
                          _invoiceRow(theme, 'Time', timeStr, isHeader: true),
                        ],
                        const SizedBox(height: 4),
                        _invoiceRow(theme, 'Status', e.status.toUpperCase(), isHeader: true, valueColor: statusColor),
                      ],
                    ),
                  ),
                  // From / To
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FROM', style: theme.textTheme.labelSmall?.copyWith(color: sub, letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text('Cajun Local', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: nav)),
                              const SizedBox(height: 2),
                              Text('Payment', style: theme.textTheme.bodySmall?.copyWith(color: sub)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TO', style: theme.textTheme.labelSmall?.copyWith(color: sub, letterSpacing: 0.8)),
                              const SizedBox(height: 4),
                              Text(_customerName(), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: nav)),
                              if (e.businessId != null || e.userId != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  e.businessId != null ? 'Business' : 'User',
                                  style: theme.textTheme.bodySmall?.copyWith(color: sub),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Line item table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    color: nav.withValues(alpha: 0.06),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('DESCRIPTION', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: sub, letterSpacing: 0.5)),
                        ),
                        Expanded(
                          child: Text('AMOUNT', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: sub, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  // Line item
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            _relatedLoaded ? _lineItemDescription() : PaymentHistoryEntry.paymentTypeLabel(e.paymentType),
                            style: theme.textTheme.bodyLarge?.copyWith(color: nav),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '\$${e.amount.toStringAsFixed(2)} ${e.currency.toUpperCase()}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: nav,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Total
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: nav)),
                        Text(
                          '\$${e.amount.toStringAsFixed(2)} ${e.currency.toUpperCase()}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.specGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Payment reference
                  if (e.stripePaymentIntentId != null && e.stripePaymentIntentId!.isNotEmpty) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PAYMENT REFERENCE', style: theme.textTheme.labelSmall?.copyWith(color: sub, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          SelectableText(
                            e.stripePaymentIntentId!,
                            style: theme.textTheme.bodySmall?.copyWith(color: nav, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ],
                ),
              ),
                // Related / actions below the invoice card
                if (_relatedLoaded) ...[
                  const SizedBox(height: 20),
                  _RelatedSection(
                    entry: e,
                    businessName: widget.businessName,
                    userName: widget.userName,
                    relatedAd: _relatedAd,
                    businessPlanName: _businessPlanName,
                    userPlan: _userPlan,
                  ),
                ]
                else ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _invoiceRow(ThemeData theme, String label, String value, {bool isHeader = false, Color? valueColor}) {
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: valueColor ?? (isHeader ? AppTheme.specWhite.withValues(alpha: 0.95) : nav),
      fontWeight: isHeader ? FontWeight.w600 : null,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: isHeader ? AppTheme.specWhite.withValues(alpha: 0.8) : sub))),
        Expanded(child: Text(value, style: valueStyle)),
      ],
    );
  }
}

/// Displays resolved relation: subscription plan name, ad headline, and View links.
class _RelatedSection extends StatelessWidget {
  const _RelatedSection({
    required this.entry,
    this.businessName,
    this.userName,
    this.relatedAd,
    this.businessPlanName,
    this.userPlan,
  });

  final PaymentHistoryEntry entry;
  final String? businessName;
  final String? userName;
  final BusinessAd? relatedAd;
  final String? businessPlanName;
  final UserPlan? userPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.75);

    String description;
    List<Widget> actions = [];
    if (entry.paymentType == 'business_subscription') {
      description = businessPlanName != null && businessPlanName!.isNotEmpty
          ? '${businessName ?? entry.businessId ?? 'Business'} — $businessPlanName'
          : (businessName ?? entry.businessId ?? 'Business subscription');
      if (entry.businessId != null) {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppOutlinedButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminBusinessDetailScreen(businessId: entry.businessId!),
                  ),
                );
              },
              icon: const Icon(Icons.business_rounded, size: 18),
              label: const Text('View business'),
            ),
          ),
        );
      }
    } else if (entry.paymentType == 'user_subscription') {
      description = userPlan != null
          ? '${userName ?? entry.userId ?? 'User'} — ${userPlan!.name}'
          : (userName ?? entry.userId ?? 'User subscription');
    } else if (entry.paymentType == 'advertisement') {
      description = relatedAd != null
          ? (relatedAd!.headline?.isNotEmpty == true ? relatedAd!.headline! : 'Ad')
          : (entry.referenceId != null ? 'Ad (ref: ${entry.referenceId!.substring(0, 8)}…)' : 'Advertisement');
      if (relatedAd != null) {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppOutlinedButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                AdminAdDetailSlideOut.show(
                  navigator.context,
                  ad: relatedAd!,
                  onClose: () {},
                  onUpdated: () {},
                );
              },
              icon: const Icon(Icons.campaign_rounded, size: 18),
              label: const Text('View ad'),
            ),
          ),
        );
      }
    } else {
      description = entry.referenceId != null ? entry.referenceId! : PaymentHistoryEntry.paymentTypeLabel(entry.paymentType);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.specWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nav.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: nav,
            ),
          ),
          if (entry.referenceId != null && entry.referenceId!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reference: ${entry.referenceId!}',
              style: theme.textTheme.labelSmall?.copyWith(color: sub),
            ),
          ],
          ...actions,
        ],
      ),
    );
  }
}
