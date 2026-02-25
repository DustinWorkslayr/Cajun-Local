import 'package:flutter/material.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/data/models/business_hours.dart';
import 'package:my_app/core/data/repositories/business_hours_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/core/utils/hours_format.dart';

/// Editable weekly hours. Loads from/saves to BusinessHoursRepository.
/// Use in listing edit (More tab) and admin business overview.
class BusinessHoursEditor extends StatefulWidget {
  const BusinessHoursEditor({
    super.key,
    required this.businessId,
    this.onSaved,
  });

  final String businessId;
  final VoidCallback? onSaved;

  @override
  State<BusinessHoursEditor> createState() => _BusinessHoursEditorState();
}

const List<String> _days = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

String _dayLabel(String day) {
  final cap = day[0].toUpperCase() + day.substring(1);
  return cap;
}

String _formatToAmPm(TimeOfDay t) {
  if (t.hour == 0) return '12:${t.minute.toString().padLeft(2, '0')} AM';
  if (t.hour == 12) return '12:${t.minute.toString().padLeft(2, '0')} PM';
  if (t.hour < 12) return '${t.hour}:${t.minute.toString().padLeft(2, '0')} AM';
  return '${t.hour - 12}:${t.minute.toString().padLeft(2, '0')} PM';
}

TimeOfDay? _timeFromAmPm(String amPm) {
  final s = parseAmPmTo24h(amPm);
  if (s == null) return null;
  final parts = s.split(':');
  if (parts.isEmpty) return null;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.specWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.specNavy.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy),
          ),
        ),
      ),
    );
  }
}

class _BusinessHoursEditorState extends State<BusinessHoursEditor> {
  final BusinessHoursRepository _repo = BusinessHoursRepository();
  bool _loading = true;
  bool _saving = false;
  final Map<String, TextEditingController> _openControllers = {};
  final Map<String, TextEditingController> _closeControllers = {};
  final Map<String, bool> _closed = {};
  /// Open 24 hours (store 00:00–23:59).
  final Map<String, bool> _open24h = {};

  @override
  void initState() {
    super.initState();
    for (final d in _days) {
      _openControllers[d] = TextEditingController();
      _closeControllers[d] = TextEditingController();
      _closed[d] = true;
      _open24h[d] = false;
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _openControllers.values) {
      c.dispose();
    }
    for (final c in _closeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _repo.getForBusiness(widget.businessId);
    if (mounted) {
      setState(() {
        _loading = false;
        for (final d in _days) {
          BusinessHours? h;
          try {
            h = list.firstWhere((e) => e.dayOfWeek == d);
          } catch (_) {}
          if (h != null) {
            final is24 = is24Hours(h.openTime, h.closeTime);
            _open24h[d] = is24;
            if (is24) {
              _openControllers[d]!.text = '12:00 AM';
              _closeControllers[d]!.text = '11:59 PM';
            } else {
              _openControllers[d]!.text = format24hToAmPm(h.openTime) ?? h.openTime ?? '';
              _closeControllers[d]!.text = format24hToAmPm(h.closeTime) ?? h.closeTime ?? '';
            }
            _closed[d] = h.isClosed ?? true;
          } else {
            _closed[d] = true;
          }
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final list = _days.map((d) {
        final isClosed = _closed[d] ?? true;
        final open24 = _open24h[d] ?? false;
        String? openTime;
        String? closeTime;
        if (!isClosed) {
          if (open24) {
            openTime = '00:00';
            closeTime = '23:59';
          } else {
            openTime = parseAmPmTo24h(_openControllers[d]!.text.trim());
            closeTime = parseAmPmTo24h(_closeControllers[d]!.text.trim());
            if (openTime != null && openTime.isEmpty) openTime = null;
            if (closeTime != null && closeTime.isEmpty) closeTime = null;
          }
        }
        return BusinessHours(
          businessId: widget.businessId,
          dayOfWeek: d,
          openTime: openTime,
          closeTime: closeTime,
          isClosed: isClosed,
        );
      }).toList();
      await _repo.setForBusiness(widget.businessId, list);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hours saved.')));
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._days.map((d) {
          final isClosed = _closed[d] ?? true;
          final open24 = _open24h[d] ?? false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    _dayLabel(d),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.specNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Checkbox(
                  value: !isClosed,
                  onChanged: (v) => setState(() {
                    _closed[d] = !(v ?? false);
                    if (_closed[d] == true) _open24h[d] = false;
                  }),
                  fillColor: WidgetStateProperty.resolveWith(
                    (Set<WidgetState> states) =>
                        states.contains(WidgetState.selected)
                            ? AppTheme.specNavy
                            : null,
                  ),
                ),
                const Text('Open', style: TextStyle(fontSize: 12, color: AppTheme.specNavy)),
                const SizedBox(width: 8),
                if (!isClosed) ...[
                  Checkbox(
                    value: open24,
                    onChanged: (v) => setState(() {
                      _open24h[d] = v ?? false;
                      if (_open24h[d] == true) {
                        _openControllers[d]!.text = '12:00 AM';
                        _closeControllers[d]!.text = '11:59 PM';
                      }
                    }),
                    fillColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected) ? AppTheme.specNavy : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() {
                      _open24h[d] = !open24;
                      if (_open24h[d] == true) {
                        _openControllers[d]!.text = '12:00 AM';
                        _closeControllers[d]!.text = '11:59 PM';
                      }
                    }),
                    child: Text('Open 24 hrs', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specNavy)),
                  ),
                  const SizedBox(width: 12),
                  if (!open24) ...[
                    _TimeChip(
                      label: _openControllers[d]!.text.isEmpty ? 'Open' : _openControllers[d]!.text,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _timeFromAmPm(_openControllers[d]!.text) ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (t != null && mounted) {
                          setState(() => _openControllers[d]!.text = _formatToAmPm(t));
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('–', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy)),
                    ),
                    _TimeChip(
                      label: _closeControllers[d]!.text.isEmpty ? 'Close' : _closeControllers[d]!.text,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _timeFromAmPm(_closeControllers[d]!.text) ?? const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (t != null && mounted) {
                          setState(() => _closeControllers[d]!.text = _formatToAmPm(t));
                        }
                      },
                    ),
                  ],
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        AppSecondaryButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save hours'),
        ),
      ],
    );
  }
}
