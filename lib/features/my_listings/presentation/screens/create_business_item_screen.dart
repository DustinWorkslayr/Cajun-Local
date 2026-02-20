import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';

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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _discountController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final id = 'd-u-${DateTime.now().millisecondsSinceEpoch}';
    final deal = MockDeal(
      id: id,
      listingId: widget.listingId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      discount: _discountController.text.trim().isEmpty ? null : _discountController.text.trim(),
      code: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
      isActive: true,
    );
    MockData.addDeal(deal);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deal created')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create deal'),
        actions: [
          TextButton(
            onPressed: _save,
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
                hintText: 'e.g. 10% off lunch',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Valid Monday–Friday 11am–2pm. Dine-in only.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Discount (optional)',
                hintText: 'e.g. 10% off',
                border: OutlineInputBorder(),
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
              ),
              textCapitalization: TextCapitalization.characters,
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _rewardController = TextEditingController();
    _punchesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rewardController.dispose();
    _punchesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final punches = int.tryParse(_punchesController.text.trim());
    if (punches == null || punches < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of punches (1 or more)')),
      );
      return;
    }
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loyalty card created')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create loyalty card'),
        actions: [
          TextButton(
            onPressed: _save,
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
                labelText: 'Card title',
                hintText: 'e.g. Bayou Bites loyalty',
                border: OutlineInputBorder(),
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
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Enter a number (1 or more)';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen to create a new menu item (or section) for a listing.
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = MockMenuItem(
      listingId: widget.listingId,
      name: _nameController.text.trim(),
      price: _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      section: _sectionController.text.trim().isEmpty ? null : _sectionController.text.trim(),
    );
    MockData.addMenuItem(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu item added')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add menu item'),
        actions: [
          TextButton(
            onPressed: _save,
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
                hintText: 'e.g. Gumbo',
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
                hintText: 'e.g. Mains, Sides, Bar',
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
                hintText: 'Chicken & andouille, dark roux',
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
