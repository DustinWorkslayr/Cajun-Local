import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/features/listing/presentation/screens/claim_business_screen.dart';

/// Shown after a user creates a new listing. Explains that the listing is pending approval
/// and they must submit proof of ownership (same flow as claiming) before it can be approved.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final uid = AppDataScope.of(context).authRepository.currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pending approval',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding.left, 24, padding.right, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 56,
                  color: AppTheme.specNavy,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Listing submitted',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.specNavy,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                businessName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.specNavy.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your listing is pending approval. Before we can approve it, you need to submit proof of ownership—similar to claiming an existing business. Choose a document type (e.g. business license, DBA filing) and add details so we can verify you represent this business.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.specNavy.withValues(alpha: 0.85),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                height: 4,
                width: 56,
                decoration: BoxDecoration(
                  color: AppTheme.specGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),
              if (uid != null)
                AppSecondaryButton(
                  onPressed: () async {
                    final submitted = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => ClaimBusinessScreen(
                          businessId: businessId,
                          businessName: businessName,
                          userId: uid,
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    if (submitted == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Proof submitted. We\'ll review and get back to you.',
                          ),
                          backgroundColor: AppTheme.specNavy,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 22),
                  label: const Text('Submit proof of ownership'),
                )
              else
                Text(
                  'Sign in to submit proof of ownership.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to My Listings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
