import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_app/core/data/services/punch_edge_functions_service.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/punch_code_invalid_dialog.dart';

/// One business option for the quick-scan business picker (legacy).
class QuickScanBusiness {
  const QuickScanBusiness({required this.id, required this.name});
  final String id;
  final String name;
}

/// One loyalty (punch) card option for the quick-scan picker — all active programs across user's businesses.
class QuickScanLoyaltyCard {
  const QuickScanLoyaltyCard({
    required this.programId,
    required this.programTitle,
    required this.businessName,
    this.businessId,
  });
  final String programId;
  final String programTitle;
  final String businessName;
  final String? businessId;
}

/// Bottom sheet: (1) Select loyalty card (all active punch cards across user's businesses),
/// (2) Scanner for quick punch validation.
void showQuickScanSheet(
  BuildContext context, {
  List<QuickScanBusiness>? businesses,
  List<QuickScanLoyaltyCard>? loyaltyCards,
}) {
  assert(
    (businesses != null && businesses.isNotEmpty) ||
    (loyaltyCards != null && loyaltyCards.isNotEmpty),
  );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QuickScanSheet(
      businesses: businesses ?? const [],
      loyaltyCards: loyaltyCards ?? const [],
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}

class _QuickScanSheet extends StatefulWidget {
  const _QuickScanSheet({
    required this.businesses,
    required this.loyaltyCards,
    required this.onClose,
  });

  final List<QuickScanBusiness> businesses;
  final List<QuickScanLoyaltyCard> loyaltyCards;
  final VoidCallback onClose;

  @override
  State<_QuickScanSheet> createState() => _QuickScanSheetState();
}

class _QuickScanSheetState extends State<_QuickScanSheet> {
  QuickScanBusiness? _selectedBusiness;
  QuickScanLoyaltyCard? _selectedCard;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToScannerWithBusiness(QuickScanBusiness business) {
    setState(() {
      _selectedBusiness = business;
      _selectedCard = null;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _goToScannerWithCard(QuickScanLoyaltyCard card) {
    setState(() {
      _selectedBusiness = null;
      _selectedCard = card;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _backToPicker() {
    setState(() {
      _selectedBusiness = null;
      _selectedCard = null;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  String get _scannerTitle {
    if (_selectedCard != null) {
      return '${_selectedCard!.businessName} — ${_selectedCard!.programTitle}';
    }
    return _selectedBusiness?.name ?? 'Business';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.specOffWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Flexible(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPicker(),
                _buildScanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildPicker() {
    final theme = Theme.of(context);
    if (widget.loyaltyCards.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Select loyalty card to scan',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.specNavy,
                  ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: widget.loyaltyCards.length,
              itemBuilder: (context, index) {
                final card = widget.loyaltyCards[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.specGold.withValues(alpha: 0.2),
                      child: const Icon(Icons.loyalty_rounded, color: AppTheme.specNavy),
                    ),
                    title: Text(
                      card.programTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.specNavy,
                      ),
                    ),
                    subtitle: Text(
                      card.businessName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.specNavy.withValues(alpha: 0.8),
                      ),
                    ),
                    trailing: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.specGold),
                    onTap: () => _goToScannerWithCard(card),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            'Select business to scan',
            style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.specNavy,
                ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: widget.businesses.length,
            itemBuilder: (context, index) {
              final b = widget.businesses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.specNavy.withValues(alpha: 0.1),
                    child: const Icon(Icons.store_rounded, color: AppTheme.specNavy),
                  ),
                  title: Text(
                    b.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  subtitle: const Text('Active loyalty punch cards'),
                  trailing: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.specGold),
                  onTap: () => _goToScannerWithBusiness(b),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanner() {
    return _ScannerSlide(
      title: 'Scan punch — $_scannerTitle',
      onBack: _backToPicker,
      onScanSuccess: widget.onClose,
    );
  }
}

class _ScannerSlide extends StatefulWidget {
  const _ScannerSlide({
    required this.title,
    required this.onBack,
    required this.onScanSuccess,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onScanSuccess;

  @override
  State<_ScannerSlide> createState() => _ScannerSlideState();
}

class _ScannerSlideState extends State<_ScannerSlide> {
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
            content: Text(
              result.message ?? 'The customer earned a punch.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) widget.onScanSuccess();
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
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Material(
            color: AppTheme.specNavy,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: widget.onBack,
                      tooltip: 'Back to list',
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
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
                          Text(
                            'Validating punch…',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
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
                    "Position the customer's QR code within the frame",
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
