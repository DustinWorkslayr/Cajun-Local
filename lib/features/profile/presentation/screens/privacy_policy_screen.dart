import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';

/// Privacy policy screen. Uses app design (specOffWhite, specNavy, specGold).
/// Detailed policy for Cajun Local: local businesses only, members only, right to reject.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 32);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
              _Section(
                title: 'Last updated',
                body: 'This privacy policy applies to Cajun Local and the website cajunlocal.com. We may update this policy from time to time; the “Last updated” date at the top of the app or site reflects the latest version.',
              ),
              _Section(
                title: 'Who we are',
                body: 'Cajun Local is a members-only platform for local businesses and community members in our region. We are not a national or global marketplace. We focus exclusively on locally owned and operated businesses and reserve the right to decline or remove any business or member that does not align with our community-focused, local-only values. We do not accept mega corporations or large chains as listed businesses.',
              ),
              _Section(
                title: 'Information we collect',
                body: 'We collect information you provide when you create an account (such as name, email, and profile details), when you claim or manage a business (business details, contact information, hours, menu, deals), and when you use the app (such as claimed deals, loyalty punch card enrollment, and preferences like parish/category filters). We may also collect device and usage information (e.g., device type, app version) to improve the service.',
              ),
              _Section(
                title: 'How we use your information',
                body: 'We use your information to provide and improve Cajun Local (e.g., showing you relevant local deals and businesses, managing your claimed deals and punch cards, enabling business owners to manage listings and form submissions). We may use your email to send you transactional messages (e.g., account or approval notifications) and, if you opt in, marketing or community updates. We do not sell your personal information to third parties.',
              ),
              _Section(
                title: 'Sharing of information',
                body: 'We may share information with service providers that help us operate the platform (e.g., hosting, analytics, email). When you interact with a business (e.g., claim a deal, submit a contact form), that business may receive relevant information (e.g., your name or contact details as needed for redemption or follow-up). We may disclose information if required by law or to protect our rights, users, or the public.',
              ),
              _Section(
                title: 'Membership and eligibility',
                body: 'Cajun Local is a members-only service. We reserve the right to accept, reject, or remove any member or business at our discretion. We prioritize locally owned businesses and do not allow mega corporations or large chains to join as listed businesses. By using the app or cajunlocal.com, you agree to our membership terms and community standards.',
              ),
              _Section(
                title: 'Data retention and security',
                body: 'We retain your information for as long as your account is active or as needed to provide the service and comply with legal obligations. We use reasonable technical and organizational measures to protect your data. No method of transmission or storage is 100% secure; we encourage strong passwords and prompt reporting of any suspected misuse.',
              ),
              _Section(
                title: 'Your choices and rights',
                body: 'You can update your profile and preferences in the app. You may request access to, correction of, or deletion of your personal information by contacting us (e.g., via the app or cajunlocal.com). If you are in a jurisdiction with additional privacy rights (e.g., GDPR, CCPA), you may have the right to object to certain processing, restrict processing, or data portability; contact us to exercise those rights.',
              ),
              _Section(
                title: 'Children',
                body: 'Cajun Local is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us so we can delete it.',
              ),
              _Section(
                title: 'Contact',
                body: 'For privacy-related questions or requests, please contact us through the Cajun Local app or at cajunlocal.com.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.specGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'By using Cajun Local, you agree to this Privacy Policy. We are committed to supporting our local community and keeping your information protected.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
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
