import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// About Cajun Local screen. Uses app design (specOffWhite, specNavy, specGold).
/// Describes platform: local businesses only, members only, right to reject, no mega corps; mentions cajunlocal.com.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 32);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(
          'About Cajun Local',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: AppLayout.constrainSection(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.specWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.specNavy.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        size: 56,
                        color: AppTheme.specGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cajun Local',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.specNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Local businesses. Community first.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _Section(
                title: 'What is Cajun Local?',
                body: 'Cajun Local is a members-only platform that connects our community with locally owned businesses. We are not a national marketplace or a home for big-box chains. Our focus is exclusively on local businesses—restaurants, shops, services, and venues that are part of the fabric of our region. You can learn more and join us at cajunlocal.com.',
              ),
              _Section(
                title: 'Local businesses only',
                body: 'We only list and support locally owned and operated businesses. We do not accept mega corporations, large national chains, or franchises that are not independently owned in our area. Our goal is to help real local owners reach their neighbors with deals, menus, events, and loyalty programs—so the community and the local economy both win.',
              ),
              _Section(
                title: 'Members only',
                body: 'Cajun Local is a members-only service. Both businesses and community members join by creating an account. This helps us keep the platform focused, respectful, and valuable. Members can browse and claim deals, enroll in punch cards, and support local; businesses can manage their listing, hours, menu, and promotions. We expect all members to follow our community standards.',
              ),
              _Section(
                title: 'Right to accept or decline',
                body: 'We reserve the right to accept, reject, or remove any business or member at our sole discretion. Not every business or applicant will be a fit for Cajun Local. We may decline or remove listings that do not meet our local-only criteria, that misrepresent themselves, or that violate our policies. We may also suspend or remove member accounts that abuse the platform or other users. We are committed to keeping Cajun Local a trusted, local-first community.',
              ),
              _Section(
                title: 'No mega corps',
                body: 'We explicitly do not allow mega corporations or large chains to join as listed businesses. Our platform is for local ownership and local identity. If you are a local business owner and want to be part of Cajun Local, we welcome you to apply through the app or at cajunlocal.com.',
              ),
              _Section(
                title: 'Website and app',
                body: 'Cajun Local is available as this app and on the web at cajunlocal.com. Our privacy policy, terms, and support information apply to both. For the latest updates and to sign up, visit cajunlocal.com.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      'cajunlocal.com',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.specNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visit our website to learn more, sign up, or get in touch.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.specGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
