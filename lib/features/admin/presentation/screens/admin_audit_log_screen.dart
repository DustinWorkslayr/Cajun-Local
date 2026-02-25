import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/audit_log_entry.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/theme/app_layout.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/admin/presentation/screens/admin_audit_log_detail_screen.dart';

/// Compact single-line-style card to keep list height small for long audit logs.
class _AuditLogCompactCard extends StatelessWidget {
  const _AuditLogCompactCard({
    required this.action,
    required this.subtitle,
    required this.timeStr,
    required this.userShort,
    this.targetShort,
    required this.onTap,
  });

  final String action;
  final String subtitle;
  final String timeStr;
  final String userShort;
  final String? targetShort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.specGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, color: AppTheme.specNavy, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            action,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: nav,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall?.copyWith(color: sub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: sub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userShort != '—' || targetShort != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          if (userShort != '—')
                            _tinyChip(theme, 'user: $userShort'),
                          if (targetShort != null)
                            _tinyChip(theme, targetShort!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: sub),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tinyChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.specNavy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppTheme.specNavy.withValues(alpha: 0.85),
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final AuditLogRepository _repo = AuditLogRepository();

  List<AuditLogEntry> _entries = [];
  int _totalCount = 0;
  bool _loading = true;
  bool _countLoading = false;
  String? _loadError;
  int _page = 0;
  int _pageSize = AuditLogRepository.defaultPageSize;
  String _searchQuery = '';
  String _searchDebounce = '';


  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final offset = _page * _pageSize;
      final list = await _repo.list(
        limit: _pageSize,
        offset: offset,
        search: _searchDebounce.isEmpty ? null : _searchDebounce,
      );
      if (mounted) {
        setState(() {
          _entries = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadCount() async {
    if (!mounted) return;
    setState(() => _countLoading = true);
    try {
      final total = await _repo.count(search: _searchDebounce.isEmpty ? null : _searchDebounce);
      if (mounted) setState(() { _totalCount = total; _countLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _totalCount = -1; _countLoading = false; });
    }
  }

  void _runSearch() {
    setState(() {
      _searchDebounce = _searchQuery;
      _page = 0;
    });
    _load();
    _loadCount();
  }

  /// Short date/time for compact card: "2/21 15:45"
  static String _formatShort(DateTime? d) {
    if (d == null) return '—';
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _showDetail(AuditLogEntry e) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminAuditLogDetailScreen(entry: e),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
        _loadCount();
      }
    });
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final padding = AppLayout.horizontalPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding.left, 12, padding.right, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search action, table, id, details…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _runSearch(),
                ),
              ),
              const SizedBox(width: 8),
              AppPrimaryButton(
                onPressed: _loading ? null : _runSearch,
                expanded: false,
                icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search_rounded, size: 20),
                label: const Text('Search'),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 8),
          child: Row(
            children: [
              Text('Page size:', style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                  DropdownMenuItem(value: 100, child: Text('100')),
                  DropdownMenuItem(value: 200, child: Text('200')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() { _pageSize = v; _page = 0; });
                  _load();
                  _loadCount();
                },
              ),
              const Spacer(),
              if (_countLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else if (_totalCount >= 0)
                Text(
                  'Total: $_totalCount',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading && _entries.isEmpty && _loadError == null
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                            const SizedBox(height: 16),
                            Text(
                              _loadError!,
                              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loading ? null : () { setState(() => _loadError = null); _load(); },
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _entries.isEmpty
                      ? Center(
                          child: Text(
                            _searchDebounce.isEmpty ? 'No audit entries.' : 'No matches for "$_searchDebounce".',
                            style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                      padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 16),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final e = _entries[index];
                        final target = [
                          if (e.targetTable != null) e.targetTable,
                          if (e.targetId != null) (e.targetId!.length > 12 ? '${e.targetId!.substring(0, 8)}…' : e.targetId),
                        ].whereType<String>().join(' · ');
                        final subtitle = target.isNotEmpty
                            ? target
                            : ((e.details ?? '').length > 60 ? '${(e.details ?? '').substring(0, 60)}…' : (e.details ?? '—'));
                        final userShort = e.userId != null && e.userId!.length > 8 ? '${e.userId!.substring(0, 8)}…' : (e.userId ?? '—');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _AuditLogCompactCard(
                            action: e.action,
                            subtitle: subtitle,
                            timeStr: _formatShort(e.createdAt),
                            userShort: userShort,
                            targetShort: target.isEmpty ? null : (target.length > 24 ? '${target.substring(0, 24)}…' : target),
                            onTap: () => _showDetail(e),
                          ),
                        );
                      },
                    ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _page <= 0 || _loading
                    ? null
                    : () {
                        setState(() => _page--);
                        _load();
                      },
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous page',
              ),
              const SizedBox(width: 8),
              Text(
                'Page ${_page + 1}'
                '${_totalCount >= 0 ? " · ${_page * _pageSize + 1}–${_page * _pageSize + _entries.length} of $_totalCount" : ""}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loading
                    ? null
                    : (_totalCount >= 0 && (_page + 1) * _pageSize >= _totalCount) || (_totalCount < 0 && _entries.length < _pageSize)
                        ? null
                        : () {
                            setState(() => _page++);
                            _load();
                          },
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next page',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) return _buildBody(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : () { _load(); _loadCount(); },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}

