import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/business_link.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/data/repositories/business_links_repository.dart';
import 'package:my_app/core/theme/theme.dart';

/// Editable social/website links. Loads from/saves to BusinessLinksRepository.
/// Use in listing edit (More tab) and admin business overview.
class BusinessLinksEditor extends StatefulWidget {
  const BusinessLinksEditor({
    super.key,
    required this.businessId,
    this.onSaved,
  });

  final String businessId;
  final VoidCallback? onSaved;

  @override
  State<BusinessLinksEditor> createState() => _BusinessLinksEditorState();
}

class _BusinessLinksEditorState extends State<BusinessLinksEditor> {
  final BusinessLinksRepository _repo = BusinessLinksRepository();
  List<BusinessLink> _links = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getForBusiness(widget.businessId);
    if (mounted) setState(() { _links = list; _loading = false; });
  }

  Future<void> _addLink() async {
    final labelController = TextEditingController();
    final urlController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add link'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g. Facebook, Website',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          AppPrimaryButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            expanded: false,
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (added != true || !mounted) return;
    try {
      await _repo.insert(
        businessId: widget.businessId,
        url: urlController.text.trim().isEmpty ? 'https://' : urlController.text.trim(),
        label: labelController.text.trim().isEmpty ? null : labelController.text.trim(),
        sortOrder: _links.length,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link added.')));
        _load();
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteLink(BusinessLink link) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove link?'),
        content: Text('Remove "${link.label ?? link.url}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          AppDangerButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.delete(link.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link removed.')));
        _load();
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        if (_links.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No links yet. Add your website, Facebook, Instagram, etc.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.75),
              ),
            ),
          )
        else
          ..._links.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppTheme.specWhite,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    leading: Icon(Icons.link_rounded, color: AppTheme.specNavy, size: 22),
                    title: Text(
                      link.label ?? link.url,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.specNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: link.label != null && link.label != link.url
                        ? Text(
                            link.url,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: AppTheme.specRed, size: 22),
                      onPressed: () => _deleteLink(link),
                      tooltip: 'Remove link',
                    ),
                  ),
                ),
              )),
        const SizedBox(height: 8),
        AppOutlinedButton(
          onPressed: _addLink,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add link'),
        ),
      ],
    );
  }
}
