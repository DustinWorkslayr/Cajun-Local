import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/repositories/business_events_repository.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/repositories/menu_repository.dart';
import 'package:my_app/core/data/repositories/punch_card_programs_repository.dart';
import 'package:my_app/core/data/services/app_storage_service.dart';
import 'package:my_app/core/data/services/storage_upload_constants.dart';
import 'package:my_app/core/subscription/business_tier_service.dart';
import 'package:my_app/core/supabase/supabase_config.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/shared/widgets/business_tier_upgrade_dialog.dart';

/// Screen to create a new deal (coupon) for a listing.
class CreateDealScreen extends StatefulWidget {
  const CreateDealScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends State<CreateDealScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountController;
  late TextEditingController _codeController;
  late TextEditingController _percentageController;
  late TextEditingController _amountOffController;
  BusinessTier? _tier;
  int _activeDealCount = 0;
  bool _tierLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  /// Required: user must select a deal type. Null until selected.
  String? _dealType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _discountController = TextEditingController();
    _codeController = TextEditingController();
    _percentageController = TextEditingController();
    _amountOffController = TextEditingController();
    _loadTierAndCount();
  }

  Future<void> _loadTierAndCount() async {
    if (!SupabaseConfig.isConfigured) {
      if (mounted) setState(() => _tierLoading = false);
      return;
    }
    final tier = await BusinessTierService().getTierForBusiness(widget.listingId);
    final count = await DealsRepository().countActiveForBusiness(widget.listingId);
    if (mounted) {
      setState(() {
        _tier = tier;
        _activeDealCount = count;
        _tierLoading = false;
        if (_dealType != null && !_availableDealTypesForTier(tier).contains(_dealType)) {
          _dealType = null;
        }
      });
    }
  }

  List<String> _availableDealTypesForTier(BusinessTier? t) {
    final list = List<String>.from(DealTypes.simple);
    if (t == BusinessTier.localPartner) list.addAll(DealTypes.advanced);
    return list;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    _percentageController.dispose();
    _amountOffController.dispose();
    super.dispose();
  }

  /// Deal types available for the current tier (simple for all; flash/member_only for Local Partner only).
  List<String> get _availableDealTypes => _availableDealTypesForTier(_tier);

  bool get _isPercentage => _dealType == DealTypes.percentage;
  bool get _isFixed => _dealType == DealTypes.fixed;
  bool get _isBogo => _dealType == DealTypes.bogo;
  bool get _isFreebie => _dealType == DealTypes.freebie;
  bool get _descriptionRequiredByType => _isBogo || _isFreebie;

  static String _dealTypeLabel(String type) {
    switch (type) {
      case DealTypes.percentage:
        return 'Percentage off';
      case DealTypes.fixed:
        return 'Dollar off';
      case DealTypes.bogo:
        return 'BOGO';
      case DealTypes.freebie:
        return 'Free item with purchase';
      case DealTypes.other:
        return 'Other';
      case DealTypes.flash:
        return 'Flash deal';
      case DealTypes.memberOnly:
        return 'Member-only deal';
      default:
        return type;
    }
  }

  static String _titleHintForType(String type) {
    switch (type) {
      case DealTypes.percentage:
        return 'e.g. 10% off lunch';
      case DealTypes.fixed:
        return 'e.g. \$5 off \$25 purchase';
      case DealTypes.bogo:
        return 'e.g. Buy one get one half off';
      case DealTypes.freebie:
        return 'e.g. Free dessert with entrée';
      case DealTypes.flash:
      case DealTypes.memberOnly:
        return 'e.g. Flash lunch special';
      default:
        return 'e.g. Weekend special';
    }
  }

  static String _descriptionHintForType(String? type) {
    switch (type) {
      case DealTypes.percentage:
      case DealTypes.fixed:
        return 'Valid Monday–Friday 11am–2pm. Dine-in only.';
      case DealTypes.bogo:
        return 'e.g. Buy one entrée at full price, get second at 50% off. Dine-in only.';
      case DealTypes.freebie:
        return 'e.g. Order any entrée and get a free dessert.';
      default:
        return 'Valid Monday–Friday 11am–2pm. Dine-in only.';
    }
  }

  bool get _atDealLimit {
    if (_tier == null) return false;
    return _activeDealCount >= BusinessTierService.maxActiveDeals(_tier!);
  }

  Future<void> _save() async {
    if (_dealType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deal type')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_tier != null && _atDealLimit) {
      await BusinessTierUpgradeDialog.show(
        context,
        message: BusinessTierService.upgradeMessageForDealLimit(_tier!),
      );
      return;
    }
    if (_tier != null && !BusinessTierService.canCreateDealType(_tier!, _dealType!)) {
      await BusinessTierUpgradeDialog.show(
        context,
        message: BusinessTierService.upgradeMessageForAdvancedFeatures(),
      );
      return;
    }
    final scope = AppDataScope.of(context);
    final useSupabase = scope.dataSource.useSupabase;
    final isManager = useSupabase
        ? (await scope.dataSource.getCurrentUser()).ownedListingIds.contains(widget.listingId)
        : false;

    String title = _titleController.text.trim();
    String? description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    if (_isPercentage && _percentageController.text.trim().isNotEmpty) {
      final pct = _percentageController.text.trim();
      description = '$pct% off. ${description ?? ''}'.trim();
    }
    if (_isFixed && _amountOffController.text.trim().isNotEmpty) {
      final amount = _amountOffController.text.trim();
      description = '\$$amount off. ${description ?? ''}'.trim();
    }

    if (useSupabase && isManager) {
      await DealsRepository().insert(
        businessId: widget.listingId,
        title: title,
        dealType: _dealType!,
        description: description,
        startDate: _startDate,
        endDate: _endDate,
      );
    } else {
      final id = 'd-u-${DateTime.now().millisecondsSinceEpoch}';
      final deal = MockDeal(
        id: id,
        listingId: widget.listingId,
        title: title,
        description: description ?? title,
        discount: _discountController.text.trim().isEmpty ? null : _discountController.text.trim(),
        code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        isActive: true,
        dealType: _dealType,
      );
      MockData.addDeal(deal);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deal created')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 24);
    final canSchedule = _tier != null && BusinessTierService.canScheduleDealDates(_tier!);

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
        title: Text(
          'Create deal',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: AppLayout.constrainSection(
          context,
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_tierLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else ...[
                  if (_atDealLimit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: AppTheme.specGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppTheme.specNavy, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "You've reached your plan limit ($_activeDealCount active deal${_activeDealCount == 1 ? '' : 's'}). Upgrade to add more.",
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy),
                                ),
                              ),
                              TextButton(
                                onPressed: () => BusinessTierUpgradeDialog.show(
                                  context,
                                  message: BusinessTierService.upgradeMessageForDealLimit(_tier!),
                                ),
                                child: const Text('Upgrade'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Deal type (required first)
                  DropdownButtonFormField<String>(
                    initialValue: _dealType,
                    decoration: const InputDecoration(
                      labelText: 'Deal type',
                      hintText: 'Select a deal type',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                    items: _availableDealTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_dealTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _dealType = v),
                    validator: (v) => v == null || v.isEmpty ? 'Select a deal type' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: _dealType == null ? 'e.g. 10% off lunch' : _titleHintForType(_dealType!),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (_isPercentage) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _percentageController,
                      decoration: const InputDecoration(
                        labelText: 'Percentage off (%)',
                        hintText: 'e.g. 10',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter percentage off';
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1 || n > 100) return 'Enter a number between 1 and 100';
                        return null;
                      },
                    ),
                  ],
                  if (_isFixed) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountOffController,
                      decoration: const InputDecoration(
                        labelText: 'Amount off (\$)',
                        hintText: 'e.g. 5',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppTheme.specWhite,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter amount off';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Enter a positive amount';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: _descriptionRequiredByType ? 'Description' : 'Description (optional)',
                      hintText: _descriptionHintForType(_dealType),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (_descriptionRequiredByType && (v == null || v.trim().isEmpty)) {
                        return _isBogo ? 'Enter BOGO details (e.g. Buy one get one half off)' : 'Enter description (e.g. Free item with purchase)';
                      }
                      return null;
                    },
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (canSchedule) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('Start date (optional)', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy)),
                      subtitle: Text(
                        _startDate == null
                            ? 'None'
                            : '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded, color: AppTheme.specNavy),
                      onTap: _pickStartDate,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: AppTheme.specWhite,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text('End date (optional)', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy)),
                      subtitle: Text(
                        _endDate == null
                            ? 'None'
                            : '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded, color: AppTheme.specNavy),
                      onTap: _pickEndDate,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      tileColor: AppTheme.specWhite,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount (optional)',
                      hintText: 'e.g. 10% off',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Promo code (optional)',
                      hintText: 'e.g. CAJUN10',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    onPressed: _atDealLimit ? null : _save,
                    child: const Text('Save deal'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen to create a new event for a listing.
class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  DateTime _eventDate = DateTime.now();
  DateTime? _endDate;
  String? _imageUrl;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploadingImage || !SupabaseConfig.isConfigured) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedImageExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final ext = name.contains('.') ? name.split('.').last : 'jpg';
      final url = await AppStorageService().uploadEventImage(
        businessId: widget.listingId,
        bytes: bytes,
        extension: ext,
      );
      if (mounted) setState(() { _imageUrl = url; _uploadingImage = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final scope = AppDataScope.of(context);
    final useSupabase = scope.dataSource.useSupabase;
    final isManager = useSupabase
        ? (await scope.dataSource.getCurrentUser()).ownedListingIds.contains(widget.listingId)
        : false;
    if (useSupabase && isManager) {
      await BusinessEventsRepository().insert(
        businessId: widget.listingId,
        title: _titleController.text.trim(),
        eventDate: _eventDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        endDate: _endDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        imageUrl: _imageUrl,
      );
    } else {
      final id = 'e-u-${DateTime.now().millisecondsSinceEpoch}';
      final ev = MockEvent(
        id: id,
        listingId: widget.listingId,
        title: _titleController.text.trim(),
        eventDate: _eventDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        endDate: _endDate,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        imageUrl: _imageUrl,
        status: 'pending',
      );
      MockData.addEvent(ev);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created (pending approval)')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate(BuildContext context, bool isEndDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEndDate ? (_endDate ?? _eventDate) : _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEndDate) {
        _endDate = picked;
        if (_endDate!.isBefore(_eventDate)) _eventDate = _endDate!;
      } else {
        _eventDate = picked;
        if (_endDate != null && _endDate!.isBefore(_eventDate)) _endDate = _eventDate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create event'),
        actions: [
          TextButton(
            onPressed: () => _save(),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Live music night, Trivia Tuesday',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Details about the event',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Event date'),
              subtitle: Text(
                '${_eventDate.year}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () => _pickDate(context, false),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('End date (optional)'),
              subtitle: Text(
                _endDate == null
                    ? 'None'
                    : '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () => _pickDate(context, true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                hintText: 'e.g. Main dining room, Patio',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _uploadingImage ? null : _pickAndUploadImage,
              icon: _uploadingImage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_rounded, size: 20),
              label: Text(_uploadingImage ? 'Uploading...' : (_imageUrl != null ? 'Change event image' : 'Add event image (optional)')),
            ),
            if (_imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Image added', style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

/// Screen to create a new loyalty punch card for a listing.
class CreateLoyaltyScreen extends StatefulWidget {
  const CreateLoyaltyScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<CreateLoyaltyScreen> createState() => _CreateLoyaltyScreenState();
}

class _CreateLoyaltyScreenState extends State<CreateLoyaltyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _rewardController;
  late TextEditingController _punchesController;
  BusinessTier? _tier;
  bool _tierLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _rewardController = TextEditingController();
    _punchesController = TextEditingController();
    _loadTier();
  }

  Future<void> _loadTier() async {
    if (!SupabaseConfig.isConfigured) {
      if (mounted) {
        setState(() => _tierLoading = false);
      }
      return;
    }
    final tier = await BusinessTierService().getTierForBusiness(widget.listingId);
    if (mounted) {
      setState(() {
        _tier = tier;
        _tierLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rewardController.dispose();
    _punchesController.dispose();
    super.dispose();
  }

  bool get _canCreatePunchCard => _tier != null && BusinessTierService.canCreatePunchCard(_tier!);

  Future<void> _save() async {
    if (!_canCreatePunchCard) {
      await BusinessTierUpgradeDialog.show(
        context,
        message: BusinessTierService.upgradeMessageForAdvancedFeatures(),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final punches = int.tryParse(_punchesController.text.trim());
    if (punches == null || punches < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of punches (1 or more)')),
      );
      return;
    }
    final scope = AppDataScope.of(context);
    final useSupabase = scope.dataSource.useSupabase;
    final isManager = useSupabase
        ? (await scope.dataSource.getCurrentUser()).ownedListingIds.contains(widget.listingId)
        : false;
    if (useSupabase && isManager) {
      await PunchCardProgramsRepository().insert(
        businessId: widget.listingId,
        title: _titleController.text.trim(),
        rewardDescription: _rewardController.text.trim(),
        punchesRequired: punches,
        isActive: true,
      );
    } else {
      final id = 'p-u-${DateTime.now().millisecondsSinceEpoch}';
      final card = MockPunchCard(
        id: id,
        listingId: widget.listingId,
        title: _titleController.text.trim(),
        rewardDescription: _rewardController.text.trim(),
        punchesRequired: punches,
        punchesEarned: 0,
        isActive: true,
      );
      MockData.addPunchCard(card);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loyalty card created')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.padding(context, top: 16, bottom: 24);
    final locked = !_tierLoading && !_canCreatePunchCard;

    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.specOffWhite,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppTheme.specNavy,
        ),
        title: Text(
          'Create loyalty card',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: AppLayout.constrainSection(
          context,
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_tierLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  )
                else if (locked) ...[
                  Icon(Icons.lock_rounded, size: 56, color: AppTheme.specNavy.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'Loyalty cards require Local Partner',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    BusinessTierService.upgradeMessageForAdvancedFeatures(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    onPressed: () => BusinessTierUpgradeDialog.show(
                      context,
                      message: BusinessTierService.upgradeMessageForAdvancedFeatures(),
                    ),
                    child: const Text('Upgrade to Local Partner'),
                  ),
                ]
                else ...[
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Card title',
                      hintText: 'e.g. Bayou Bites loyalty',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rewardController,
                    decoration: const InputDecoration(
                      labelText: 'Reward description',
                      hintText: 'e.g. Free gumbo after 8 visits',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Describe the reward' : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _punchesController,
                    decoration: const InputDecoration(
                      labelText: 'Punches required',
                      hintText: 'e.g. 8',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.specWhite,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Enter a number (1 or more)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    onPressed: _save,
                    child: const Text('Save loyalty card'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen to add an item to a listing's menu (products, services, or offerings).
class CreateMenuItemScreen extends StatefulWidget {
  const CreateMenuItemScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<CreateMenuItemScreen> createState() => _CreateMenuItemScreenState();
}

class _CreateMenuItemScreenState extends State<CreateMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _sectionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _sectionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final scope = AppDataScope.of(context);
    final useSupabase = scope.dataSource.useSupabase;
    final isManager = useSupabase
        ? (await scope.dataSource.getCurrentUser()).ownedListingIds.contains(widget.listingId)
        : false;
    if (useSupabase && isManager) {
      final sectionName = _sectionController.text.trim().isEmpty
          ? 'General'
          : _sectionController.text.trim();
      final sectionId = await MenuRepository().getOrCreateSectionId(widget.listingId, sectionName);
      await MenuRepository().insertItem(
        sectionId: sectionId,
        name: _nameController.text.trim(),
        price: _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isAvailable: true,
      );
    } else {
      final item = MockMenuItem(
        listingId: widget.listingId,
        name: _nameController.text.trim(),
        price: _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        section: _sectionController.text.trim().isEmpty ? null : _sectionController.text.trim(),
      );
      MockData.addMenuItem(item);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add item'),
        actions: [
          TextButton(
            onPressed: () => _save(),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'e.g. Product or service name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter item name' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sectionController,
              decoration: const InputDecoration(
                labelText: 'Section (optional)',
                hintText: 'e.g. Products, Services, Packages',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (optional)',
                hintText: 'e.g. \$12',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Short description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
