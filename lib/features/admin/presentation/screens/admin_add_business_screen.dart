import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/models/business_category.dart';
import 'package:my_app/core/data/models/subcategory.dart';
import 'package:my_app/core/data/repositories/business_repository.dart';
import 'package:my_app/core/data/repositories/category_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// State is fixed to Louisiana for this app.
const String _kStateLouisiana = 'LA';

/// Admin: add unclaimed business(es) — single form with category dropdown and
/// subcategory multi-select; bulk import via CSV file upload.
class AdminAddBusinessScreen extends StatefulWidget {
  const AdminAddBusinessScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminAddBusinessScreen> createState() => _AdminAddBusinessScreenState();
}

class _AdminAddBusinessScreenState extends State<AdminAddBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();

  /// Parish (required): businesses can only be in allowed parishes. Store id so dropdown value is always in items.
  String? _selectedParishId;
  List<MockParish> _parishes = [];

  List<BusinessCategory> _categories = [];
  List<Subcategory> _subcategories = [];
  /// Store category id so dropdown value is always in items (avoids red screen).
  String? _selectedCategoryId;
  final Set<String> _selectedSubcategoryIds = {};
  bool _categoriesLoading = true;
  bool _parishesLoading = true;
  bool _subcategoriesLoading = false;

  String? _singleMessage;
  bool _singleSuccess = false;
  bool _singleLoading = false;

  /// CSV bulk import is admin-only.
  bool? _isAdmin;
  bool _initialLoadDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _loadCategories();
      _loadParishes();
      AppDataScope.of(context).authRepository.isAdmin().then((v) {
        if (mounted) setState(() => _isAdmin = v);
      });
    }
  }

  Future<void> _loadParishes() async {
    try {
      final ds = AppDataScope.of(context).dataSource;
      final list = await ds.getParishes();
      if (mounted) {
        setState(() {
          _parishes = list;
          _parishesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _parishes = [];
          _parishesLoading = false;
        });
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final list = await CategoryRepository().listCategories();
      if (mounted) {
        setState(() {
          _categories = list;
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = [];
          _categoriesLoading = false;
        });
      }
    }
  }

  Future<void> _onCategoryChanged(String? categoryId) async {
    BusinessCategory? category;
    if (categoryId != null) {
      for (final c in _categories) {
        if (c.id == categoryId) { category = c; break; }
      }
    }
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubcategoryIds.clear();
      _subcategories = [];
      _subcategoriesLoading = category != null;
    });
    if (category == null) return;
    try {
      final list = await CategoryRepository().listSubcategories(categoryId: category.id);
      if (mounted) {
        setState(() {
          _subcategories = list;
          _subcategoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _subcategories = [];
          _subcategoriesLoading = false;
        });
      }
    }
  }

  void _toggleSubcategory(String id) {
    setState(() {
      if (_selectedSubcategoryIds.contains(id)) {
        _selectedSubcategoryIds.remove(id);
      } else {
        _selectedSubcategoryIds.add(id);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submitSingle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() {
        _singleMessage = 'Please select a category.';
        _singleSuccess = false;
      });
      return;
    }
    if (_selectedParishId == null) {
      setState(() {
        _singleMessage = 'Please select a parish.';
        _singleSuccess = false;
      });
      return;
    }
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) {
      setState(() {
        _singleMessage = 'You must be signed in.';
        _singleSuccess = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _singleMessage = null;
      _singleLoading = true;
    });
    try {
      MockParish? selectedParish;
      for (final p in _parishes) {
        if (p.id == _selectedParishId) { selectedParish = p; break; }
      }
      final businessRepo = BusinessRepository();
      final businessId = await businessRepo.insertBusiness(
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId!,
        createdBy: uid,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _addressController.text.trim().isEmpty ? selectedParish?.name : null,
        parish: _selectedParishId,
        state: _kStateLouisiana,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      );
      await businessRepo.setBusinessSubcategories(businessId, _selectedSubcategoryIds.toList());
      if (!mounted) return;
      setState(() {
        _singleMessage = 'Business added (unclaimed).';
        _singleSuccess = true;
        _singleLoading = false;
      });
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      final message = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      setState(() {
        _singleMessage = message.length > 300 ? '${message.substring(0, 300)}…' : message;
        _singleSuccess = false;
        _singleLoading = false;
      });
    }
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    const cardRadius = 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: padding.left, right: padding.right),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add business',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.specNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'All businesses are in Louisiana. Add one or bulk import (admin only).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.specNavy.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 4,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.specGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: EdgeInsets.symmetric(horizontal: padding.left),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.specWhite,
              borderRadius: BorderRadius.circular(cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Single business',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Business name',
                      hintText: 'e.g. Acme Cafe',
                      filled: true,
                      fillColor: AppTheme.specOffWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                      ),
                      labelStyle: TextStyle(color: AppTheme.specNavy),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      filled: true,
                      fillColor: AppTheme.specOffWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                      ),
                      labelStyle: TextStyle(color: AppTheme.specNavy),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _parishesLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                        )
                      :                       DropdownButtonFormField<String>(
                          initialValue: (_selectedParishId != null && _parishes.any((p) => p.id == _selectedParishId))
                              ? _selectedParishId
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Parish',
                            filled: true,
                            fillColor: AppTheme.specOffWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                            ),
                            labelStyle: TextStyle(color: AppTheme.specNavy),
                          ),
                          hint: const Text('Select parish'),
                          items: _parishes
                              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                              .toList(),
                          onChanged: (id) => setState(() => _selectedParishId = id),
                          validator: (v) => v == null || v.isEmpty ? 'Please select a parish' : null,
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      filled: true,
                      fillColor: AppTheme.specOffWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                      ),
                      labelStyle: TextStyle(color: AppTheme.specNavy),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    decoration: InputDecoration(
                      labelText: 'Website',
                      filled: true,
                      fillColor: AppTheme.specOffWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                      ),
                      labelStyle: TextStyle(color: AppTheme.specNavy),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  if (_categoriesLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: (_selectedCategoryId != null && _categories.any((c) => c.id == _selectedCategoryId))
                          ? _selectedCategoryId
                          : null,
                      hint: const Text('Select category'),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: AppTheme.specOffWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                        ),
                        labelStyle: TextStyle(color: AppTheme.specNavy),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: _onCategoryChanged,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Please select a category' : null,
                    ),
                  if (_selectedCategoryId != null) ...[
                    const SizedBox(height: 16),
                    if (_subcategoriesLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
                      )
                    else
                      InkWell(
                        onTap: _subcategories.isEmpty
                            ? null
                            : () => _showSubcategoryPicker(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Subcategories',
                            hintText: 'Tap to select',
                            filled: true,
                            fillColor: AppTheme.specOffWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.specNavy.withValues(alpha: 0.2)),
                            ),
                            labelStyle: TextStyle(color: AppTheme.specNavy),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _selectedSubcategoryIds.isEmpty
                                    ? [
                                        Text(
                                          _subcategories.isEmpty
                                              ? 'None available'
                                              : 'None selected',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color: AppTheme.specNavy.withValues(alpha: 0.7)),
                                        ),
                                      ]
                                    : _subcategories
                                        .where((s) =>
                                            _selectedSubcategoryIds.contains(s.id))
                                        .map((s) => Chip(
                                              label: Text(s.name),
                                              deleteIcon: const Icon(Icons.close_rounded, size: 18),
                                              onDeleted: () => _toggleSubcategory(s.id),
                                              backgroundColor: AppTheme.specGold.withValues(alpha: 0.2),
                                            ))
                                        .toList(),
                              ),
                              if (_subcategories.isNotEmpty)
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: AppTheme.specNavy.withValues(alpha: 0.6),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                  if (_singleMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _singleMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _singleSuccess
                              ? AppTheme.specNavy
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  AppSecondaryButton(
                    onPressed: _singleLoading ? null : _submitSingle,
                    icon: _singleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specWhite),
                          )
                        : const Icon(Icons.add_rounded, size: 22),
                    label: Text(_singleLoading ? 'Adding…' : 'Add business'),
                  ),
                ],
              ),
            ),
          ),
          if (_isAdmin == true) ...[
            const SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding.left),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.specGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Bulk import (admin only)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.specNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BulkImportSection(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSubcategoryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.specOffWhite,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select subcategories',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.specNavy,
                            ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _subcategories.length,
                    itemBuilder: (_, i) {
                      final s = _subcategories[i];
                      final selected = _selectedSubcategoryIds.contains(s.id);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (_) => _toggleSubcategory(s.id),
                        title: Text(s.name),
                        fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) => states.contains(WidgetState.selected) ? AppTheme.specNavy : Colors.transparent),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) return _buildBody(context);
    final theme = Theme.of(context);
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
          'Add business',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.specNavy,
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }
}

/// Bulk import: pick CSV file, parse, resolve category/subcategories, insert.
class _BulkImportSection extends StatefulWidget {
  @override
  State<_BulkImportSection> createState() => _BulkImportSectionState();
}

class _BulkImportSectionState extends State<_BulkImportSection> {
  String? _summary;
  List<String> _rowErrors = [];
  bool _loading = false;
  String? _pickedFileName;

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var i = 0;
    while (i < line.length) {
      if (line[i] == '"') {
        i++;
        final sb = StringBuffer();
        while (i < line.length) {
          if (line[i] == '"') {
            i++;
            if (i < line.length && line[i] == '"') {
              sb.write('"');
              i++;
            } else {
              break;
            }
          } else {
            sb.write(line[i]);
            i++;
          }
        }
        result.add(sb.toString());
      } else {
        final end = line.indexOf(',', i);
        if (end == -1) {
          result.add(line.substring(i).trim());
          break;
        }
        result.add(line.substring(i, end).trim());
        i = end + 1;
      }
    }
    return result;
  }

  Future<void> _pickAndImport() async {
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    if (uid == null) {
      setState(() {
        _summary = 'You must be signed in.';
        _rowErrors = [];
      });
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.single.bytes == null) {
      setState(() {
        _summary = null;
        _pickedFileName = null;
      });
      return;
    }
    final bytes = result.files.single.bytes!;
    final text = utf8.decode(bytes);
    final fileName = result.files.single.name;
    setState(() {
      _loading = true;
      _summary = null;
      _rowErrors = [];
      _pickedFileName = fileName;
    });
    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      setState(() {
        _summary = 'File has no rows.';
        _loading = false;
      });
      return;
    }
    final header = _parseCsvLine(lines.first);
    final nameIdx = header.indexWhere((h) => h.toLowerCase() == 'name');
    final categoryIdx =
        header.indexWhere((h) => h.toLowerCase() == 'category');
    final subcategoriesIdx =
        header.indexWhere((h) => h.toLowerCase() == 'subcategories');
    final addressIdx = header.indexWhere((h) => h.toLowerCase() == 'address');
    final cityIdx = header.indexWhere((h) => h.toLowerCase() == 'city');
    final stateIdx = header.indexWhere((h) => h.toLowerCase() == 'state');
    final phoneIdx = header.indexWhere((h) => h.toLowerCase() == 'phone');
    final websiteIdx =
        header.indexWhere((h) => h.toLowerCase() == 'website');
    if (nameIdx < 0 || categoryIdx < 0) {
      setState(() {
        _summary = 'CSV must have "name" and "category" columns.';
        _rowErrors = [];
        _loading = false;
      });
      return;
    }
    int added = 0;
    final errors = <String>[];
    final categoryRepo = CategoryRepository();
    final businessRepo = BusinessRepository();
    for (var rowNum = 2; rowNum <= lines.length; rowNum++) {
      final row = _parseCsvLine(lines[rowNum - 1]);
      if (row.length <= nameIdx || row.length <= categoryIdx) {
        errors.add('Row $rowNum: not enough columns');
        continue;
      }
      final name = row[nameIdx].trim();
      final categoryName = row[categoryIdx].trim();
      if (name.isEmpty) {
        errors.add('Row $rowNum: name is empty');
        continue;
      }
      final cat = await categoryRepo.getCategoryByName(categoryName);
      if (cat == null) {
        errors.add('Row $rowNum: category "$categoryName" not found');
        continue;
      }
      final subcategoriesCell = subcategoriesIdx >= 0 &&
              row.length > subcategoriesIdx
          ? row[subcategoriesIdx]
          : '';
      final subcategoryIds = await categoryRepo.resolveSubcategoryIdsByNames(
          cat.id, subcategoriesCell);
      try {
        final businessId = await businessRepo.insertBusiness(
          name: name,
          categoryId: cat.id,
          createdBy: uid,
          address:
              addressIdx >= 0 && row.length > addressIdx
                  ? row[addressIdx].trim()
                  : null,
          city:
              cityIdx >= 0 && row.length > cityIdx
                  ? row[cityIdx].trim()
                  : null,
          state: stateIdx >= 0 && row.length > stateIdx
              ? row[stateIdx].trim()
              : _kStateLouisiana,
          phone:
              phoneIdx >= 0 && row.length > phoneIdx
                  ? row[phoneIdx].trim()
                  : null,
          website:
              websiteIdx >= 0 && row.length > websiteIdx
                  ? row[websiteIdx].trim()
                  : null,
        );
        await businessRepo.setBusinessSubcategories(
            businessId, subcategoryIds);
        added++;
      } catch (e) {
        errors.add('Row $rowNum: ${e.toString()}');
      }
    }
    setState(() {
      _summary = '$added added, ${errors.length} failed.';
      _rowErrors = errors;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Upload a CSV with columns: name, category, subcategories (comma-separated), and optionally address, city, state, phone, website. State defaults to Louisiana.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.specNavy.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 12),
        AppOutlinedButton(
          onPressed: _loading ? null : _pickAndImport,
          icon: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specNavy),
                )
              : const Icon(Icons.upload_file_rounded),
          label: Text(_loading ? 'Importing…' : 'Upload CSV file'),
        ),
        if (_pickedFileName != null) ...[
          const SizedBox(height: 8),
          Text(
            'File: $_pickedFileName',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.7),
            ),
          ),
        ],
        if (_summary != null) ...[
          const SizedBox(height: 12),
          Text(
            _summary!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.specNavy,
            ),
          ),
        ],
        if (_rowErrors.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._rowErrors.take(20).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    e,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ),
          if (_rowErrors.length > 20)
            Text(
              '… and ${_rowErrors.length - 20} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.specNavy.withValues(alpha: 0.7),
              ),
            ),
        ],
      ],
    );
  }
}
