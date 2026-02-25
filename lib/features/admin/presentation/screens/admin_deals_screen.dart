import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/deal.dart';
import 'package:my_app/core/data/repositories/deals_repository.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_deal_screen.dart';
import 'package:my_app/features/admin/presentation/screens/admin_deal_detail_screen.dart';

/// Admin list of deals with optional status filter.
class AdminDealsScreen extends StatelessWidget {
  const AdminDealsScreen({
    super.key,
    this.status,
    this.embeddedInShell = false,
  });

  final String? status;
  final bool embeddedInShell;

  void _openAddDeal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AdminAddDealScreen()),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = DealsRepository();
    return FutureBuilder<List<Deal>>(
        future: repo.listForAdmin(status: status),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                status != null ? 'No $status deals.' : 'No deals.',
                style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final d = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(d.title),
                  subtitle: Text('${d.status} · ${d.dealType}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AdminDealDetailScreen(dealId: d.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (embeddedInShell) {
      return Stack(
        children: [
          _buildBody(context),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _openAddDeal(context),
              tooltip: 'Add deal',
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(status != null ? 'Deals ($status)' : 'All deals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add deal',
            onPressed: () => _openAddDeal(context),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
}
