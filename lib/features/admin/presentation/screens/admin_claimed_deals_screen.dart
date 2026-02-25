import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/data/models/profile.dart';
import 'package:my_app/core/data/models/user_deal.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/core/data/repositories/user_deals_repository.dart';

/// Admin: list all claimed deals (user_deals) and "Mark as used" for redemption.
class AdminClaimedDealsScreen extends StatefulWidget {
  const AdminClaimedDealsScreen({
    super.key,
    this.embeddedInShell = false,
  });

  final bool embeddedInShell;

  @override
  State<AdminClaimedDealsScreen> createState() => _AdminClaimedDealsScreenState();
}

class _AdminClaimedDealsScreenState extends State<AdminClaimedDealsScreen> {
  List<UserDeal>? _userDeals;
  Map<String, Deal> _dealById = {};
  Map<String, Profile> _profileByUserId = {};
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _userDeals == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final auth = AppDataScope.of(context).authRepository;
      final userDealsRepo = UserDealsRepository(authRepository: auth);
      final dealsRepo = DealsRepository();

      final list = await userDealsRepo.listForAdmin();
      final dealIds = list.map((e) => e.dealId).toSet().toList();

      final profiles = await auth.listProfilesForAdmin();
      final profileByUserId = {for (var p in profiles) p.userId: p};

      final dealById = <String, Deal>{};
      for (final id in dealIds) {
        final d = await dealsRepo.getByIdForAdmin(id);
        if (d != null) dealById[id] = d;
      }

      if (mounted) {
        setState(() {
          _userDeals = list;
          _dealById = dealById;
          _profileByUserId = profileByUserId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAsUsed(UserDeal ud) async {
    if (ud.usedAt != null) return;
    final auth = AppDataScope.of(context).authRepository;
    final repo = UserDealsRepository(authRepository: auth);
    try {
      await repo.setUsedAt(ud.userId, ud.dealId);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  static String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final list = _userDeals ?? [];
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No claimed deals.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final ud = list[index];
          final deal = _dealById[ud.dealId];
          final profile = _profileByUserId[ud.userId];
          final dealTitle = deal?.title ?? ud.dealId;
          final userName = profile?.displayName ?? profile?.email ?? ud.userId;
          final used = ud.usedAt != null;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dealTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (used)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Used ${_formatDate(ud.usedAt!)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: () => _markAsUsed(ud),
                          child: const Text('Mark as used'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'User: $userName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Claimed ${_formatDate(ud.claimedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInShell) return _buildBody(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claimed deals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}
