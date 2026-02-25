import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/ad_package.dart';
import 'package:my_app/core/data/repositories/ad_packages_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_ad_package_form_screen.dart';
import 'package:my_app/features/admin/presentation/widgets/admin_shared.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: list and manage ad packages.
class AdminAdPackagesScreen extends StatelessWidget {
  const AdminAdPackagesScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  void _openForm(BuildContext context, [AdPackage? pkg]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminAdPackageFormScreen(package: pkg),
      ),
    );
    if (result == true && context.mounted) {
      // Parent can refresh by key or state; for Stateless we rely on user re-opening or pull.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = AdPackagesRepository();

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Ad packages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.specNavy),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<AdPackage>>(
            future: repo.list(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.specNavy),
                );
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No ad packages. Add one to define placements and pricing.',
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
                          label: const Text('Add ad package'),
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
                        label: const Text('Add ad package'),
                      ),
                    ),
                  ...list.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AdminListCard(
                          title: p.name,
                          subtitle:
                              '\$${p.price.toStringAsFixed(0)} · ${p.durationDays} days · ${AdPackage.placementLabel(p.placement)}',
                          badges: [
                            AdminBadgeData(p.isActive ? 'Active' : 'Inactive',
                                color: p.isActive ? null : AppTheme.specRed),
                          ],
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.specGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded,
                                color: AppTheme.specNavy, size: 26),
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
                tooltip: 'Add ad package',
                child: const Icon(Icons.add_rounded),
              ),
            ),
        ],
      ),
    );
  }
}
