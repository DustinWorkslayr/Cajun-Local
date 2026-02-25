import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/business.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/subscription/business_tier_service.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Admin: create a new deal. Uses homepage-style theme (specOffWhite, specNavy, specGold).
/// [initialBusinessId] pre-selects the business when opening from a business detail screen.
class AdminAddDealScreen extends StatefulWidget {
  const AdminAddDealScreen({super.key, this.initialBusinessId});

  final String? initialBusinessId;

  @override
  State<AdminAddDealScreen> createState() => _AdminAddDealScreenState();
}

class _AdminAddDealScreenState extends State<AdminAddDealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Business> _businesses = [];
  bool _loading = true;
  Business? _selectedBusiness;
  String _dealType = 'other';
  bool _isActive = true;
  bool _saving = false;
  String? _message;
  bool _success = false;
  BusinessTier? _tier;
  int _activeDealCount = 0;
  bool _tierLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    final list = await BusinessRepository().listForAdmin();
    if (mounted) {
      setState(() {
        _businesses = list;
        _loading = false;
        if (list.isNotEmpty) {
          if (widget.initialBusinessId != null) {
            final match = list.where((b) => b.id == widget.initialBusinessId);
            _selectedBusiness = match.isEmpty ? list.first : match.first;
          } else {
            _selectedBusiness ??= list.first;
          }
        }
      });
      if (_selectedBusiness != null) _loadTierAndCount(_selectedBusiness!.id);
    }
  }

  Future<void> _loadTierAndCount(String businessId) async {
    setState(() => _tierLoading = true);
    final tier = await BusinessTierService().getTierForBusiness(businessId);
    final count = await DealsRepository().countActiveForBusiness(businessId);
    if (mounted) {
      setState(() {
        _tier = tier;
        _activeDealCount = count;
        _tierLoading = false;
        if (!BusinessTierService.canCreateDealType(tier, _dealType)) {
          _dealType = 'other';
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      setState(() {
        _message = 'Please select a business.';
        _success = false;
      });
      return;
    }
    if (_tier != null && !BusinessTierService.canCreateDealType(_tier!, _dealType)) {
      setState(() {
        _message = 'This business is not on Local Partner. Flash and Member-only deals require Local Partner.';
        _success = false;
      });
      return;
    }
    if (_isActive && _tier != null) {
      final maxAllowed = BusinessTierService.maxActiveDeals(_tier!);
      if (_activeDealCount >= maxAllowed) {
        setState(() {
          _message = 'This business has reached the active deal limit ($maxAllowed) for their plan. Create as inactive or they can upgrade.';
          _success = false;
        });
        return;
      }
    }
    setState(() {
      _message = null;
      _saving = true;
    });
    try {
      await DealsRepository().insert(
        businessId: _selectedBusiness!.id,
        title: _titleController.text.trim(),
        dealType: _dealType,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _success = true;
          _message = 'Deal created.';
        });
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _success = false;
          _message = e.toString();
        });
      }
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
          'Add deal',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                DropdownButtonFormField<Business>(
                  key: ValueKey<String>(_selectedBusiness?.id ?? ''),
                  initialValue: _selectedBusiness,
                  decoration: const InputDecoration(
                    labelText: 'Business',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.specWhite,
                  ),
                  items: _businesses
                      .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                      .toList(),
                  onChanged: (b) {
                    setState(() => _selectedBusiness = b);
                    if (b != null) _loadTierAndCount(b.id);
                  },
                  validator: (v) => v == null ? 'Select a business' : null,
                ),
                if (_tier != null && _tierLoading == false) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.specGold.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          BusinessTierService.tierDisplayName(_tier!),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.specNavy,
                          ),
                        ),
                      ),
                      if (_tier != BusinessTier.localPartner)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '$_activeDealCount active deal(s)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.specWhite,
                    hintText: 'e.g. 10% off lunch',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('$_dealType-${_tier?.name ?? ""}'),
                  initialValue: _dealType,
                  decoration: const InputDecoration(
                    labelText: 'Deal type',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.specWhite,
                  ),
                  items: [
                    const DropdownMenuItem(value: 'percentage', child: Text('Percentage off')),
                    const DropdownMenuItem(value: 'fixed', child: Text('Dollar off')),
                    const DropdownMenuItem(value: 'bogo', child: Text('BOGO')),
                    const DropdownMenuItem(value: 'freebie', child: Text('Free item with purchase')),
                    const DropdownMenuItem(value: 'other', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'flash',
                      enabled: _tier == null || _tier == BusinessTier.localPartner,
                      child: Row(
                        children: [
                          const Text('Flash deal'),
                          if (_tier != BusinessTier.localPartner)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '(Local Partner only)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'member_only',
                      enabled: _tier == null || _tier == BusinessTier.localPartner,
                      child: Row(
                        children: [
                          const Text('Member-only deal'),
                          if (_tier != null && _tier != BusinessTier.localPartner)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '(Local Partner only)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.specNavy.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _dealType = v ?? 'other'),
                ),
                if (_tier != null && BusinessTierService.canScheduleDealDates(_tier!)) ...[
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
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppTheme.specWhite,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Active', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.specNavy)),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: AppTheme.specGold,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _success ? Colors.green : AppTheme.specRed,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppPrimaryButton(
                  onPressed: _saving ? null : _submit,
                  expanded: false,
                  child: _saving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create deal'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
