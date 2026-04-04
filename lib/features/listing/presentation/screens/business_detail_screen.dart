import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/features/listing/presentation/providers/listing_detail_provider.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_header_card.dart';
import 'package:cajun_local/features/listing/presentation/widgets/business_detail_body.dart';
import 'package:cajun_local/shared/widgets/app_bar_widget.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';

/// Business detail entry point. Backwards-compatible alias kept below.
class BusinessDetailScreen extends StatelessWidget {
  const BusinessDetailScreen({super.key, required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context) => _Loader(listingId: listingId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data loader
// ─────────────────────────────────────────────────────────────────────────────
class _Loader extends ConsumerWidget {
  const _Loader({required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingDetailControllerProvider(listingId));
    final userId = ref.watch(authControllerProvider).valueOrNull?.id;

    return async.when(
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: const AppBarWidget(title: 'Business', showBackButton: true),
            body: const Center(child: Text('Business not found')),
          );
        }
        return _Screen(
          data: data,
          currentUserId: userId,
          onReload: () => ref.read(listingDetailControllerProvider(listingId).notifier).reload(),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: const AppBarWidget(title: 'Business', showBackButton: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Couldn't load this business"),
              const SizedBox(height: 12),
              AppSecondaryButton(
                onPressed: () => ref.read(listingDetailControllerProvider(listingId).notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen scaffold
// ─────────────────────────────────────────────────────────────────────────────
class _Screen extends StatelessWidget {
  const _Screen({required this.data, required this.currentUserId, required this.onReload});
  final ListingDetailData data;
  final String? currentUserId;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final isTablet = AppLayout.isTablet(context);
    final pad = AppLayout.horizontalPadding(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.specSurfaceContainer,
        appBar: AppBarWidget(
          title: data.listing.name,
          showBackButton: true,
          actions: [
            if (data.isOwnerOrManager)
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.specNavy),
                onPressed: () {},
              ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppTheme.specNavy),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad.left, 16, pad.right, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Card (Image + Name/CTAs) ────────────────────────
              BusinessDetailHeaderCard(data: data, onReload: onReload),
              const SizedBox(height: 24),

              // ── Body (Tab strip + content + extras) ─────────────────────
              BusinessDetailBody(data: data, currentUserId: currentUserId, isTablet: isTablet, onReload: onReload),
            ],
          ),
        ),
      ),
    );
  }
}
