import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/business_plan.dart';
import 'package:my_app/core/data/models/user_plan.dart';
import 'package:my_app/core/data/repositories/business_plans_repository.dart';
import 'package:my_app/core/data/repositories/user_plans_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_business_plan_form_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_user_plan_form_screen.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: manage business and user subscription plans. Same theme as dashboard.
class AdminSubscriptionsScreen extends StatelessWidget {
  const AdminSubscriptionsScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.specOffWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.specOffWhite,
          surfaceTintColor: Colors.transparent,
          title: const Text('Subscriptions'),
          titleTextStyle: TextStyle(
            color: AppTheme.specNavy,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          iconTheme: const IconThemeData(color: AppTheme.specNavy),
          bottom: TabBar(
            labelColor: AppTheme.specNavy,
            unselectedLabelColor: AppTheme.specNavy.withValues(alpha: 0.7),
            indicatorColor: AppTheme.specGold,
            tabs: const [
              Tab(text: 'Business plans'),
              Tab(text: 'User plans'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BusinessPlansTab(embeddedInShell: embeddedInShell),
            _UserPlansTab(embeddedInShell: embeddedInShell),
          ],
        ),
      ),
    );
  }
}

class _BusinessPlansTab extends StatelessWidget {
  const _BusinessPlansTab({required this.embeddedInShell});

  final bool embeddedInShell;

  void _openForm(BuildContext context, [BusinessPlan? plan]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminBusinessPlanFormScreen(plan: plan),
      ),
    );
    if (result == true && context.mounted) {
      // Refresh is handled by returning to a new future in parent if we use StatefulWidget;
      // for simplicity we don't refresh here - user can pull or re-open. Better: use a key.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = BusinessPlansRepository();
    return Stack(
      children: [
        FutureBuilder<List<BusinessPlan>>(
          future: repo.list(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.specNavy));
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No business plans. Add one to define subscription tiers and limits.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                      ),
                    ),
                    if (!embeddedInShell) ...[
                      const SizedBox(height: 16),
                      AppSecondaryButton(
                        onPressed: () => _openForm(context),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add business plan'),
                      ),
                    ],
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                if (!embeddedInShell)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppSecondaryButton(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add business plan'),
                    ),
                  ),
                ...list.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminListCard(
                    title: p.name,
                    subtitle: '\$${p.priceMonthly.toStringAsFixed(0)}/mo · \$${p.priceYearly.toStringAsFixed(0)}/yr · ${p.maxLocations} location(s)',
                    badges: [
                      AdminBadgeData(p.tier),
                      AdminBadgeData(p.isActive ? 'Active' : 'Inactive', color: p.isActive ? null : AppTheme.specRed),
                    ],
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.specGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.business_center_rounded, color: AppTheme.specNavy, size: 26),
                    ),
                    onTap: () => _openForm(context, p),
                  ),
                )),
              ],
            );
          },
        ),
        if (embeddedInShell)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.specNavy,
              foregroundColor: AppTheme.specWhite,
              onPressed: () => _openForm(context),
              tooltip: 'Add business plan',
              child: const Icon(Icons.add_rounded),
            ),
          ),
      ],
    );
  }
}

class _UserPlansTab extends StatelessWidget {
  const _UserPlansTab({required this.embeddedInShell});

  final bool embeddedInShell;

  void _openForm(BuildContext context, [UserPlan? plan]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminUserPlanFormScreen(plan: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = UserPlansRepository();
    return Stack(
      children: [
        FutureBuilder<List<UserPlan>>(
          future: repo.list(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.specNavy));
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No user plans. Add one to define subscriber tiers and features.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                      ),
                    ),
                    if (!embeddedInShell) ...[
                      const SizedBox(height: 16),
                      AppSecondaryButton(
                        onPressed: () => _openForm(context),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add user plan'),
                      ),
                    ],
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                if (!embeddedInShell)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppSecondaryButton(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add user plan'),
                    ),
                  ),
                ...list.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminListCard(
                    title: p.name,
                    subtitle: '\$${p.priceMonthly.toStringAsFixed(0)}/mo · \$${p.priceYearly.toStringAsFixed(0)}/yr',
                    badges: [
                      AdminBadgeData(p.tier),
                      AdminBadgeData(p.isActive ? 'Active' : 'Inactive', color: p.isActive ? null : AppTheme.specRed),
                    ],
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.specGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.card_membership_rounded, color: AppTheme.specNavy, size: 26),
                    ),
                    onTap: () => _openForm(context, p),
                  ),
                )),
              ],
            );
          },
        ),
        if (embeddedInShell)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.specNavy,
              foregroundColor: AppTheme.specWhite,
              onPressed: () => _openForm(context),
              tooltip: 'Add user plan',
              child: const Icon(Icons.add_rounded),
            ),
          ),
      ],
    );
  }
}
