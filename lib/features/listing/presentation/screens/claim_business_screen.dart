import 'package:flutter/material.dart';
import 'package:my_app/core/data/repositories/business_claims_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Acceptable forms of business identification for claiming a listing.
/// Shown to the user so they know what they can submit; claim is only approved after admin review.
const List<String> kAcceptableClaimDocumentTypes = [
  'State or local business license',
  'Louisiana Secretary of State filing (e.g. LLC, corp)',
  'DBA / trade name registration',
  'State tax certificate or permit',
  'Utility bill in the business name (recent)',
  'Lease or deed showing business name and address',
  'Other (describe in details below)',
];

/// Screen for a signed-in user to submit a claim for an unclaimed business.
/// User must choose a document type and provide details; admin approves before the listing is claimed.
class ClaimBusinessScreen extends StatefulWidget {
  const ClaimBusinessScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.userId,
  });

  final String businessId;
  final String businessName;
  final String userId;

  @override
  State<ClaimBusinessScreen> createState() => _ClaimBusinessScreenState();
}

class _ClaimBusinessScreenState extends State<ClaimBusinessScreen> {
  String? _selectedDocType;
  final TextEditingController _detailsController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final docType = _selectedDocType?.trim();
    if (docType == null || docType.isEmpty) {
      setState(() {
        _error = 'Please select a form of business identification.';
      });
      return;
    }
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      setState(() {
        _error = 'Please add details (e.g. license number, where we can verify).';
      });
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    final claimDetails = 'Document type: $docType\nDetails: $details';
    final id = await BusinessClaimsRepository().insert(
      userId: widget.userId,
      businessId: widget.businessId,
      claimDetails: claimDetails,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (id != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Claim submitted. We\'ll review your information and get back to you.',
          ),
          backgroundColor: AppTheme.specNavy,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _error = 'Could not submit claim. Please try again or contact support.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: const Text('Claim this business'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding.left, 16, padding.right, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.businessName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sorry for the hassle—we just don\'t want anyone else claiming your business! '
              'To keep things safe, we need to verify you really represent this one. '
              'Please use one of the document types below (only these count), and we\'ll take a look and get back to you.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Accepted proof (choose one)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'If you\'re sending a file, PDF, JPG, or PNG works.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            ...kAcceptableClaimDocumentTypes.map((label) {
              final isSelected = _selectedDocType == label;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedDocType = label;
                    _error = null;
                  }),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.specGold.withValues(alpha: 0.2)
                          : AppTheme.specWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.specGold
                            : AppTheme.specNavy.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppTheme.specGold : AppTheme.specNavy.withValues(alpha: 0.5),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.specNavy,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Text(
              'Details (required)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.specNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'e.g. license number, permit number, or where we can verify this document',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              onChanged: (_) => setState(() => _error = null),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter details...',
                filled: true,
                fillColor: AppTheme.specWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.specGold, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specRed),
              ),
            ],
            const SizedBox(height: 24),
            AppPrimaryButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit claim for review'),
            ),
          ],
        ),
      ),
    );
  }
}
