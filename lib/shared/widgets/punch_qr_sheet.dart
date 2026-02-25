import 'package:flutter/material.dart';
import 'package:my_app/core/data/services/punch_edge_functions_service.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows a bottom sheet that generates a punch token and displays it as QR.
/// Call from My punch cards or listing detail when user is enrolled.
void showPunchQrSheet(BuildContext context, {required String userPunchCardId, required String cardTitle}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.specWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PunchQrSheet(
      userPunchCardId: userPunchCardId,
      cardTitle: cardTitle,
    ),
  );
}

class _PunchQrSheet extends StatefulWidget {
  const _PunchQrSheet({
    required this.userPunchCardId,
    required this.cardTitle,
  });

  final String userPunchCardId;
  final String cardTitle;

  @override
  State<_PunchQrSheet> createState() => _PunchQrSheetState();
}

class _PunchQrSheetState extends State<_PunchQrSheet> {
  String? _token;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await PunchEdgeFunctionsService().generatePunchToken(widget.userPunchCardId);
      if (mounted) setState(() { _token = token; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(
            widget.cardTitle,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.specNavy),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error), textAlign: TextAlign.center),
            )
          else if (_token != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.2)),
              ),
              child: QrImageView(
                data: _token!,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Show this QR to the business to earn a punch. Valid for 5 minutes.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
