import 'package:flutter/material.dart';
import 'package:cajun_local/features/businesses/data/models/business.dart';
import 'package:cajun_local/features/businesses/data/repositories/business_repository.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/admin/presentation/screens/admin_add_business_screen.dart';
import 'package:cajun_local/features/admin/presentation/screens/admin_business_detail_screen.dart';
import 'package:cajun_local/features/admin/presentation/widgets/admin_shared.dart';

/// Admin businesses: search, pagination, card grid. Tap opens full admin business edit (theme-styled, full control).
class AdminBusinessesScreen extends StatefulWidget {
  const AdminBusinessesScreen({super.key, this.status, this.embeddedInShell = false});

  final String? status;
  final bool embeddedInShell;

  @override
  State<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends State<AdminBusinessesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _pageIndex = 0;
  int _pageSize = defaultAdminPageSize;
  List<Business> _page = [];
  int _totalCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void didUpdateWidget(AdminBusinessesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _pageIndex = 0;
      _load();
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
        _pageIndex = 0;
      });
      _load();
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = BusinessRepository();
    try {
      final list = await repo.listForAdmin(
        status: widget.status,
        search: _query.isEmpty ? null : _query,
        limit: _pageSize,
        offset: _pageIndex * _pageSize,
      );
      final total = await repo.listForAdminCount(status: widget.status, search: _query.isEmpty ? null : _query);
      if (mounted) {
        setState(() {
          _page = list;
          _totalCount = total;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _page = [];
          _totalCount = 0;
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _openAddBusiness() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminAddBusinessScreen())).then((_) => _load());
  }

  void _openDetail(Business b) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => AdminBusinessDetailScreen(businessId: b.id))).then((_) => _load());
  }

  static Widget _leadingIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.specGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppTheme.specNavy, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);
    final total = _totalCount;
    final pageItems = _page;

    Widget body = Container(
      color: AppTheme.specOffWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header + search
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 20, padding.right, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.status != null ? 'Businesses · ${widget.status}' : 'Businesses',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.specNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              total == 0 ? 'No businesses' : '$total business${total == 1 ? '' : 'es'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.specNavy.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.embeddedInShell)
                        IconButton.filled(
                          onPressed: _openAddBusiness,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Add business',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AdminSearchBar(
                    controller: _searchController,
                    hint: 'Search by name, city, or address…',
                    onChanged: (_) {
                      setState(() => _pageIndex = 0);
                      _load();
                    },
                  ),
                  if (widget.status != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Filter: ${widget.status}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppTheme.specNavy)),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)),
              ),
            )
          else if (pageItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _query.isEmpty ? 'No businesses yet.' : 'No matches for "$_query".',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 8),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  final b = pageItems[index];
                  final location = [b.city, b.state].where((x) => x != null && x.toString().isNotEmpty).join(', ');
                  final subtitleParts = <String>[];
                  if (location.isNotEmpty) subtitleParts.add(location);
                  if (b.address != null && b.address!.isNotEmpty && b.address != location) {
                    subtitleParts.add(b.address!);
                  }
                  final subtitle = subtitleParts.join(' · ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AdminListCard(
                      title: b.name,
                      subtitle: subtitle.isEmpty ? null : subtitle,
                      badges: [
                        AdminBadgeData(b.status, color: b.status == 'pending' ? AppTheme.specRed : null),
                        AdminBadgeData(b.categoryId),
                      ],
                      leading: b.logoUrl != null && b.logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                b.logoUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _leadingIcon(Icons.store_rounded),
                              ),
                            )
                          : _leadingIcon(Icons.store_rounded),
                      onTap: () => _openDetail(b),
                    ),
                  );
                },
              ),
            ),
            AdminPaginationFooter(
              totalCount: total,
              pageIndex: _pageIndex,
              pageSize: _pageSize,
              onPageChanged: (p) => setState(() {
                _pageIndex = p;
                _load();
              }),
              onPageSizeChanged: (s) => setState(() {
                _pageSize = s;
                _pageIndex = 0;
                _load();
              }),
            ),
          ],
        ],
      ),
    );

    if (widget.embeddedInShell) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _openAddBusiness,
              tooltip: 'Add business',
              backgroundColor: AppTheme.specNavy,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.specOffWhite,
      appBar: AppBar(
        title: Text(widget.status != null ? 'Businesses (${widget.status})' : 'Businesses'),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), tooltip: 'Add business', onPressed: _openAddBusiness),
        ],
      ),
      body: body,
    );
  }
}
