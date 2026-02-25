import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Shown during sign-up: user must scroll to the bottom of the privacy policy
/// and tap "I agree" to continue creating an account. Pops with `true` when agreed.
class PrivacyPolicyAgreementScreen extends StatefulWidget {
  const PrivacyPolicyAgreementScreen({super.key});

  @override
  State<PrivacyPolicyAgreementScreen> createState() =>
      _PrivacyPolicyAgreementScreenState();
}

class _PrivacyPolicyAgreementScreenState
    extends State<PrivacyPolicyAgreementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 80;
    if (atBottom && !_hasScrolledToBottom && mounted) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
          color: AppTheme.specNavy,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: AppLayout.padding(context, top: 8, bottom: 24),
              child: AppLayout.constrainSection(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Please read our Privacy Policy and scroll to the bottom to agree before creating your account.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Last updated',
                      body:
                          'This privacy policy applies to Cajun Local and the website cajunlocal.com. We may update this policy from time to time.',
                    ),
                    _Section(
                      title: 'Who we are',
                      body:
                          'Cajun Local is a members-only platform for local businesses and community members. We focus exclusively on locally owned businesses and reserve the right to decline or remove any business or member. We do not accept mega corporations or large chains.',
                    ),
                    _Section(
                      title: 'Information we collect',
                      body:
                          'We collect information you provide when you create an account (name, email, profile), when you claim or manage a business, and when you use the app (claimed deals, loyalty cards, preferences). We may collect device and usage information to improve the service.',
                    ),
                    _Section(
                      title: 'How we use your information',
                      body:
                          'We use your information to provide and improve Cajun Local, manage your deals and punch cards, and enable business owners to manage listings. We may use your email for transactional messages and, if you opt in, marketing. We do not sell your personal information.',
                    ),
                    _Section(
                      title: 'Sharing of information',
                      body:
                          'We may share information with service providers that help us operate the platform. When you interact with a business (e.g., claim a deal, submit a form), that business may receive relevant information. We may disclose information if required by law.',
                    ),
                    _Section(
                      title: 'Membership and eligibility',
                      body:
                          'Cajun Local is members-only. We reserve the right to accept, reject, or remove any member or business at our discretion. We do not allow mega corporations or large chains. By using the app or cajunlocal.com, you agree to our membership terms.',
                    ),
                    _Section(
                      title: 'Data retention and security',
                      body:
                          'We retain your information for as long as your account is active or as needed. We use reasonable measures to protect your data.',
                    ),
                    _Section(
                      title: 'Your choices and rights',
                      body:
                          'You can update your profile in the app. You may request access, correction, or deletion of your information by contacting us via the app or cajunlocal.com.',
                    ),
                    _Section(
                      title: 'Children',
                      body:
                          'Cajun Local is not directed at children under 13. We do not knowingly collect personal information from children under 13.',
                    ),
                    _Section(
                      title: 'Contact',
                      body:
                          'For privacy questions or requests, contact us through the app or at cajunlocal.com.',
                    ),
                    const SizedBox(height: 24),
                    if (!_hasScrolledToBottom)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 20, color: AppTheme.specGold),
                            const SizedBox(width: 8),
                            Text(
                              'Scroll to the bottom to enable "I agree"',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: AppTheme.specWhite,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSecondaryButton(
                      onPressed: _hasScrolledToBottom
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: Text(
                        _hasScrolledToBottom
                            ? 'I agree'
                            : 'Scroll to bottom to agree',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.specNavy,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.specGold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 10),
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
