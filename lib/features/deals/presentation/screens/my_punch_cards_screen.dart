import 'package:cajun_local/features/listing/presentation/screens/business_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/shared/widgets/app_buttons.dart';
import 'package:cajun_local/shared/widgets/punch_qr_sheet.dart';
import 'package:cajun_local/features/deals/data/models/user_punch_card.dart';
import 'package:cajun_local/features/deals/data/models/punch_card_program.dart';
import 'package:cajun_local/features/deals/data/repositories/user_punch_cards_repository.dart';
import 'package:cajun_local/features/deals/data/repositories/punch_card_programs_repository.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';

/// Screen showing the current user's punch card enrollments (punches and redemption).
class MyPunchCardsScreen extends ConsumerWidget {
  const MyPunchCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final userId = ref.watch(authControllerProvider).valueOrNull?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My punch cards'),
          backgroundColor: AppTheme.specOffWhite,
          foregroundColor: AppTheme.specNavy,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sign in to see your punch cards.',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: const Text('My punch cards'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
      ),
      body: FutureBuilder<List<UserPunchCard>>(
        future: ref.read(userPunchCardsRepositoryProvider).listForUser(userId),
        builder: (context, snapshot) {
          final enrollments = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting && enrollments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (enrollments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.loyalty_outlined, size: 56, color: AppTheme.specNavy.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No punch cards yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enroll in a punch card at a business to see your progress here.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 28),
            itemCount: enrollments.length,
            itemBuilder: (context, index) {
              final enrollment = enrollments[index];
              return FutureBuilder<List<PunchCardProgram>>(
                future: ref.read(punchCardProgramsRepositoryProvider).listActive(),
                builder: (context, programsSnap) {
                  final program = (programsSnap.data ?? []).where((p) => p.id == enrollment.programId).firstOrNull;
                  if (program == null) return const SizedBox.shrink();

                  return FutureBuilder<Business?>(
                    future: BusinessRepository().getById(program.businessId),
                    builder: (context, bizSnap) {
                      final business = bizSnap.data;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MyPunchCardTile(
                          enrollment: enrollment,
                          program: program,
                          listingName: business?.name,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BusinessDetailScreen(listingId: program.businessId),
                              ),
                            );
                          },
                          onShowQr: !enrollment.isRedeemed
                              ? () => showPunchQrSheet(
                                  context,
                                  programId: program.id,
                                  cardTitle: program.title ?? 'Loyalty Program',
                                )
                              : null,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MyPunchCardTile extends StatelessWidget {
  const _MyPunchCardTile({
    required this.enrollment,
    required this.program,
    required this.onTap,
    this.listingName,
    this.onShowQr,
  });

  final UserPunchCard enrollment;
  final PunchCardProgram program;
  final VoidCallback onTap;
  final String? listingName;
  final VoidCallback? onShowQr;

  static const double _cardRadius = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.specWhite,
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      program.title ?? 'Loyalty Program',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                  ),
                  if (enrollment.isRedeemed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.specGold.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Redeemed',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.specNavy,
                        ),
                      ),
                    )
                  else
                    Icon(Icons.loyalty_rounded, size: 24, color: AppTheme.specGold),
                ],
              ),
              if (listingName != null) ...[
                const SizedBox(height: 4),
                Text(
                  listingName!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specRed, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                program.rewardDescription,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (int i = 0; i < program.punchesRequired; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < enrollment.currentPunches
                              ? AppTheme.specGold
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                          border: Border.all(
                            color: i < enrollment.currentPunches
                                ? AppTheme.specGold
                                : theme.colorScheme.outline.withValues(alpha: 0.5),
                          ),
                        ),
                        child: i < enrollment.currentPunches
                            ? Icon(Icons.check_rounded, size: 16, color: AppTheme.specNavy)
                            : null,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${enrollment.currentPunches}/${program.punchesRequired} punches',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.specNavy),
                  ),
                ],
              ),
              if (onShowQr != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppOutlinedButton(
                    onPressed: onShowQr,
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppTheme.specNavy),
                    label: Text(
                      'Show QR for punch',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.specNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
