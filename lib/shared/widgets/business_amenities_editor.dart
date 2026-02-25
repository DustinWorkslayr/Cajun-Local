import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/amenity.dart';
import 'package:my_app/core/data/repositories/amenities_repository.dart';
import 'package:my_app/core/subscription/business_tier_service.dart';
import 'package:my_app/core/theme/theme.dart';

/// Amenity picker for listing edit: shows Global + category bucket amenities.
/// Free: up to 4; Local+ or Local Partner: up to 8. Enforced by DB; UI shows limit and upgrade hint.
class BusinessAmenitiesEditor extends StatefulWidget {
  const BusinessAmenitiesEditor({
    super.key,
    required this.businessId,
    required this.categoryBucket,
    this.onSaved,
  });

  final String businessId;
  /// hire | eat | shop | explore. When null, only global amenities are shown.
  final String? categoryBucket;
  final VoidCallback? onSaved;

  @override
  State<BusinessAmenitiesEditor> createState() => _BusinessAmenitiesEditorState();
}

class _BusinessAmenitiesEditorState extends State<BusinessAmenitiesEditor> {
  final AmenitiesRepository _repo = AmenitiesRepository();
  bool _loading = true;
  bool _saving = false;
  List<Amenity> _available = [];
  final Set<String> _selectedIds = {};
  BusinessTier? _tier;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tier = await BusinessTierService().getTierForBusiness(widget.businessId);
    final amenities = await _repo.getAmenitiesForBucket(widget.categoryBucket);
    final ids = await _repo.getSelectedAmenityIdsForBusiness(widget.businessId);
    if (mounted) {
      setState(() {
        _tier = tier;
        _available = amenities;
        _selectedIds.addAll(ids);
        _loading = false;
      });
    }
  }

  int get _max => _tier != null ? BusinessTierService.maxAmenities(_tier!) : 4;

  Future<void> _toggle(Amenity a) async {
    final isSelected = _selectedIds.contains(a.id);
    if (isSelected) {
      setState(() => _selectedIds.remove(a.id));
      await _repo.removeBusinessAmenity(widget.businessId, a.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${a.name} removed.')));
        widget.onSaved?.call();
      }
      return;
    }
    if (_selectedIds.length >= _max) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BusinessTierService.upgradeMessageForAmenityLimit()),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.addBusinessAmenity(widget.businessId, a.id);
      if (mounted) {
        setState(() {
          _selectedIds.add(a.id);
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${a.name} added.')));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_selectedIds.length} of $_max selected. ${_max == 4 ? "Upgrade to add more." : ""}',
          style: theme.textTheme.bodySmall?.copyWith(color: sub),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _available.map((a) {
            final selected = _selectedIds.contains(a.id);
            return FilterChip(
              label: Text(a.name, style: TextStyle(color: selected ? nav : sub, fontSize: 13)),
              selected: selected,
              onSelected: _saving ? null : (_) => _toggle(a),
              selectedColor: AppTheme.specGold.withValues(alpha: 0.35),
              checkmarkColor: nav,
            );
          }).toList(),
        ),
      ],
    );
  }
}
