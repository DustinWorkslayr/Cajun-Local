import 'package:flutter/material.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:my_app/features/my_listings/presentation/screens/create_business_item_screen.dart';

/// Tabbed edit/dashboard for a business listing. Primary tab: Analytics; others: Details, Menu, Deals, etc.
class ListingEditScreen extends StatefulWidget {
  const ListingEditScreen({super.key, required this.listingId});

  final String listingId;

  @override
  State<ListingEditScreen> createState() => _ListingEditScreenState();
}

class _ListingEditScreenState extends State<ListingEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasPendingApproval = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDetailsSaveRequested() {
    setState(() => _hasPendingApproval = true);
  }

  @override
  Widget build(BuildContext context) {
    final listing = MockData.getListingById(widget.listingId);
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listing')),
        body: const Center(child: Text('Listing not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.name),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Analytics'),
            Tab(icon: Icon(Icons.info_outline_rounded), text: 'Details'),
            Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Menu'),
            Tab(icon: Icon(Icons.local_offer_rounded), text: 'Deals'),
            Tab(icon: Icon(Icons.more_horiz_rounded), text: 'More'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ListingDetailScreen(listingId: widget.listingId),
                ),
              );
            },
            tooltip: 'View as customer',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasPendingApproval) _PendingApprovalBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AnalyticsTab(listingId: widget.listingId),
                _DetailsTab(
                  listing: listing,
                  onSaveRequested: _onDetailsSaveRequested,
                ),
                _MenuTab(listingId: widget.listingId),
                _DealsTab(listingId: widget.listingId),
                _MoreTab(listingId: widget.listingId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.9),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 20,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Edits pending approval',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'View counts and engagement for your listing.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _StatCard(
          label: 'Profile views',
          value: '1,240',
          icon: Icons.visibility_rounded,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Saves (favorites)',
          value: '89',
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Deal redemptions',
          value: '34',
          icon: Icons.local_offer_rounded,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Punch card activations',
          value: '12',
          icon: Icons.loyalty_rounded,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatefulWidget {
  const _DetailsTab({
    required this.listing,
    required this.onSaveRequested,
  });

  final MockListing listing;
  final VoidCallback onSaveRequested;

  @override
  State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    _nameController = TextEditingController(text: l.name);
    _taglineController = TextEditingController(text: l.tagline);
    _addressController = TextEditingController(text: l.address ?? '');
    _phoneController = TextEditingController(text: l.phone ?? '');
    _websiteController = TextEditingController(text: l.website ?? '');
    _descriptionController = TextEditingController(text: l.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    final l = widget.listing;
    _nameController.text = l.name;
    _taglineController.text = l.tagline;
    _addressController.text = l.address ?? '';
    _phoneController.text = l.phone ?? '';
    _websiteController.text = l.website ?? '';
    _descriptionController.text = l.description;
    setState(() => _isEditing = false);
  }

  void _saveEdits() {
    widget.onSaveRequested();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final listing = widget.listing;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Business details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: _startEditing,
                tooltip: 'Edit details',
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _cancelEditing,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveEdits,
                    child: const Text('Save'),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isEditing) ...[
          _EditField(label: 'Name', controller: _nameController),
          _EditField(label: 'Tagline', controller: _taglineController),
          _EditField(label: 'Address', controller: _addressController),
          _EditField(label: 'Phone', controller: _phoneController),
          _EditField(label: 'Website', controller: _websiteController),
          _EditField(
            label: 'Description',
            controller: _descriptionController,
            maxLines: 4,
          ),
          _DetailRow(label: 'Category', value: listing.categoryName),
        ] else ...[
          _DetailRow(label: 'Name', value: listing.name),
          _DetailRow(label: 'Tagline', value: listing.tagline),
          if (listing.address != null && listing.address!.isNotEmpty)
            _DetailRow(label: 'Address', value: listing.address!),
          if (listing.phone != null && listing.phone!.isNotEmpty)
            _DetailRow(label: 'Phone', value: listing.phone!),
          if (listing.website != null && listing.website!.isNotEmpty)
            _DetailRow(label: 'Website', value: listing.website!),
          _DetailRow(label: 'Category', value: listing.categoryName),
          _DetailRow(label: 'Description', value: listing.description),
        ],
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final items = MockData.getMenuForListing(listingId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Menu',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateMenuItemScreen(listingId: listingId),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add item'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No menu items yet. Tap "Add item" to create one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (item.description != null)
                          Text(
                            item.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.price != null)
                    Text(
                      item.price!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            )),
      ],
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final deals = MockData.getDealsForListing(listingId);
    final cards = MockData.getPunchCardsForListing(listingId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Deals & punch cards',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${deals.length} active coupon(s), ${cards.length} punch card(s).',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateDealScreen(listingId: listingId),
                  ),
                );
              },
              icon: const Icon(Icons.local_offer_rounded, size: 20),
              label: const Text('Add deal'),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateLoyaltyScreen(listingId: listingId),
                  ),
                );
              },
              icon: const Icon(Icons.loyalty_rounded, size: 20),
              label: const Text('Add loyalty'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (deals.isEmpty && cards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No deals or punch cards yet. Use the buttons above to create one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          ...deals.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.local_offer_rounded, color: colorScheme.primary),
                  title: Text(d.title),
                  subtitle: Text(d.description),
                ),
              )),
          ...cards.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.loyalty_rounded, color: colorScheme.primary),
                  title: Text(p.title),
                  subtitle: Text('${p.punchesEarned}/${p.punchesRequired} — ${p.rewardDescription}'),
                ),
              )),
        ],
      ],
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'More options',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.schedule_rounded, color: colorScheme.primary),
          title: const Text('Hours'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.link_rounded, color: colorScheme.primary),
          title: const Text('Social & links'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.image_rounded, color: colorScheme.primary),
          title: const Text('Photos'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.notifications_rounded, color: colorScheme.primary),
          title: const Text('Notifications'),
          onTap: () {},
        ),
      ],
    );
  }
}
