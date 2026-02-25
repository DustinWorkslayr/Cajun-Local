import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_sections.dart';

/// Admin shell: verifies admin role, then shows dashboard or section content.
/// Tablet: left NavigationRail with grouped sections. Mobile: scrollable TabBar + TabBarView.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with SingleTickerProviderStateMixin {
  Future<bool>? _adminCheck;
  late List<AdminSectionItem> _sections;
  int _selectedIndex = 0;
  final Map<int, String?> _sectionStatus = {};
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _sections = buildAdminSections();
    _tabController = TabController(length: _sections.length, vsync: this, initialIndex: 0)
      ..addListener(_syncSelectedIndexFromTab);
  }

  void _syncSelectedIndexFromTab() {
    if (!_tabController!.indexIsChanging && mounted) {
      setState(() => _selectedIndex = _tabController!.index);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_syncSelectedIndexFromTab);
    _tabController?.dispose();
    super.dispose();
  }

  void _onNavigateToSection(int index, {String? status}) {
    if (index < 0 || index >= _sections.length) return;
    setState(() {
      _selectedIndex = index;
      if (status != null) {
        _sectionStatus[index] = status;
      }
    });
    _tabController?.animateTo(index);
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _sectionStatus.remove(index);
    });
    _tabController?.animateTo(index);
  }

  Widget _buildSectionContent(int index) {
    final section = _sections[index];
    final status = _sectionStatus[index];
    final onNav = index == 0 ? _onNavigateToSection : null;
    return section.builder(
      context,
      embedded: true,
      status: status,
      onNavigateToSection: onNav,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adminCheck ??= AppDataScope.of(context).authRepository.isAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Admin')),
            body: const Center(child: Text('Access denied')),
          );
        }
        final isTablet = MediaQuery.sizeOf(context).width >= AppTheme.breakpointTablet;
        final currentLabel = _sections[_selectedIndex].label;
        return Scaffold(
          backgroundColor: AppTheme.specOffWhite,
          appBar: AppBar(
            title: Text(isTablet ? currentLabel : 'Admin'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            backgroundColor: AppTheme.specOffWhite,
            foregroundColor: AppTheme.specNavy,
            elevation: 0,
            scrolledUnderElevation: 1,
            bottom: isTablet
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: [
                        for (final s in _sections) Tab(text: s.label),
                      ],
                      onTap: _onDestinationSelected,
                    ),
                  ),
          ),
          body: isTablet ? _buildTabletBody() : _buildMobileBody(),
        );
      },
    );
  }

  Widget _buildTabletBody() {
    return Row(
      children: [
        _AdminRail(
          sections: _sections,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
        ),
        Expanded(
          child: _buildSectionContent(_selectedIndex),
        ),
      ],
    );
  }

  Widget _buildMobileBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        for (var i = 0; i < _sections.length; i++)
          _buildSectionContent(i),
      ],
    );
  }
}

class _AdminRail extends StatelessWidget {
  const _AdminRail({
    required this.sections,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AdminSectionItem> sections;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String? currentGroup;
    final railWidth = 220.0;
    final children = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      if (sections[i].group != null && sections[i].group != currentGroup) {
        if (currentGroup != null) children.add(const SizedBox(height: 8));
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              sections[i].group!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        currentGroup = sections[i].group;
      }
      children.add(
        MergeSemantics(
          child: ListTile(
            leading: Icon(
              sections[i].icon,
              size: 24,
              color: selectedIndex == i
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              sections[i].label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selectedIndex == i ? FontWeight.w600 : null,
                color: selectedIndex == i
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
            selected: selectedIndex == i,
            onTap: () => onDestinationSelected(i),
          ),
        ),
      );
    }
    return Material(
      elevation: 0,
      color: AppTheme.specWhite,
      child: Container(
        width: railWidth,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: AppTheme.specNavy.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: children,
        ),
      ),
    );
  }
}
