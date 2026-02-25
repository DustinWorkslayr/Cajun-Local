import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_app/core/data/services/punch_edge_functions_service.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/punch_code_invalid_dialog.dart';

/// Full-screen QR scanner for business owners to scan a customer's punch token.
/// On successful scan, calls punch-validate edge function and shows result.
class ScanPunchScreen extends StatefulWidget {
  const ScanPunchScreen({super.key});

  @override
  State<ScanPunchScreen> createState() => _ScanPunchScreenState();
}

class _ScanPunchScreenState extends State<ScanPunchScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _processing = false;
  bool _scanned = false;
  int _punchesToAward = 1;

  static const List<int> _punchOptions = [1, 2, 3, 4, 5];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final barcode = barcodes.first;
    final token = barcode.rawValue ?? barcode.displayValue;
    if (token == null || token.trim().isEmpty) return;
    setState(() => _processing = true);
    try {
      final result = await PunchEdgeFunctionsService().validatePunch(
        token.trim(),
        punches: _punchesToAward,
      );
      if (!mounted) return;
      if (result.success) {
        _scanned = true;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Punch recorded'),
            content: Text(result.message ?? 'The customer earned a punch.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _processing = false);
        if (!mounted) return;
        await PunchCodeInvalidDialog.show(
          context,
          message: result.message,
          title: 'This code is used or invalid',
        );
      }
    } on PunchTokenException catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan punch card'),
        backgroundColor: AppTheme.specNavy,
        foregroundColor: AppTheme.specWhite,
      ),
      body: Column(
        children: [
          Material(
            color: AppTheme.specNavy.withValues(alpha: 0.95),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Punches to award:',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: _punchOptions.map((n) {
                      final selected = _punchesToAward == n;
                      return ChoiceChip(
                        label: Text('$n'),
                        selected: selected,
                        onSelected: _processing || _scanned
                            ? null
                            : (_) => setState(() => _punchesToAward = n),
                        selectedColor: AppTheme.specGold,
                        labelStyle: TextStyle(
                          color: selected ? AppTheme.specNavy : Colors.white,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        backgroundColor: Colors.white24,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Validating punch…', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.specGold, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Text(
              'Position the customer\'s QR code within the frame',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
        ],
      ),
    );
  }
}
