import 'package:flutter/material.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_category_banner_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_notification_banner_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_category_banners_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_notification_banners_screen.dart';

/// Combined admin screen: Category banners and Notification banners in a single tabbed view.
class AdminManageBannersScreen extends StatefulWidget {
  const AdminManageBannersScreen({
    super.key,
    this.status,
    this.embeddedInShell = false,
  });

  /// Optional status filter for category banners (e.g. 'pending' when opened from dashboard).
  final String? status;
  final bool embeddedInShell;

  @override
  State<AdminManageBannersScreen> createState() => _AdminManageBannersScreenState();
}

class _AdminManageBannersScreenState extends State<AdminManageBannersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _categoryRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() => setState(() {});

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    if (_tabController.index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AdminAddCategoryBannerScreen()),
      ).then((_) => setState(() => _categoryRefreshKey++));
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AdminAddNotificationBannerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      labelColor: AppTheme.specNavy,
      unselectedLabelColor: AppTheme.specNavy.withValues(alpha: 0.6),
      indicatorColor: AppTheme.specNavy,
      tabs: const [
        Tab(text: 'Category banners'),
        Tab(text: 'Notification banners'),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppTheme.specOffWhite,
          child: tabBar,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AdminCategoryBannersScreen(
                status: widget.status,
                embeddedInShell: true,
                hideFab: true,
                key: ValueKey(_categoryRefreshKey),
              ),
              const AdminNotificationBannersScreen(
                embeddedInShell: true,
                hideFab: true,
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embeddedInShell) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _onAddPressed,
              tooltip: _tabController.index == 0
                  ? 'Add category banner'
                  : 'Add notification banner',
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
        title: Text(
          widget.status != null
              ? 'Manage banners (${widget.status})'
              : 'Manage banners',
        ),
        backgroundColor: AppTheme.specOffWhite,
        foregroundColor: AppTheme.specNavy,
        bottom: PreferredSize(
          preferredSize: tabBar.preferredSize,
          child: Material(color: AppTheme.specOffWhite, child: tabBar),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: _tabController.index == 0
                ? 'Add category banner'
                : 'Add notification banner',
            onPressed: _onAddPressed,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminCategoryBannersScreen(
            status: widget.status,
            embeddedInShell: true,
            hideFab: true,
            key: ValueKey(_categoryRefreshKey),
          ),
          const AdminNotificationBannersScreen(
            embeddedInShell: true,
            hideFab: true,
          ),
        ],
      ),
    );
  }
}
