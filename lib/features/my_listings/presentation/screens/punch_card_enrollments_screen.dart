import 'package:flutter/material.dart';
import 'package:my_app/core/data/models/punch_card_enrollment.dart';
import 'package:my_app/core/data/repositories/user_punch_cards_repository.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';

/// Lists punch card enrollments for a business. Managers can redeem full cards.
class PunchCardEnrollmentsScreen extends StatefulWidget {
  const PunchCardEnrollmentsScreen({super.key, required this.businessId});

  final String businessId;

  @override
  State<PunchCardEnrollmentsScreen> createState() =>
      _PunchCardEnrollmentsScreenState();
}

class _PunchCardEnrollmentsScreenState extends State<PunchCardEnrollmentsScreen> {
  List<PunchCardEnrollment> _enrollments = [];
  bool _loading = true;
  String? _error;
  final _repo = UserPunchCardsRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.listEnrollmentsForBusiness(widget.businessId);
      if (mounted) {
        setState(() {
          _enrollments = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _redeem(PunchCardEnrollment enrollment) async {
    try {
      await _repo.redeem(enrollment.userPunchCardId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redeemed successfully')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punch card enrollments'),
        backgroundColor: AppTheme.specNavy,
        foregroundColor: AppTheme.specWhite,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: theme.textTheme.bodyLarge,
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
                )
              : _enrollments.isEmpty
                  ? Center(
                      child: Text(
                        'No enrollments yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.specNavy.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Customer · Program · Punches · Status',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.specNavy.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._enrollments.map((e) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(
                                    e.userDisplayName ?? e.userEmail ?? '—',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.specNavy,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${e.programTitle} · ${e.currentPunches}/${e.punchesRequired}',
                                    style: TextStyle(
                                      color: AppTheme.specNavy.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  trailing: e.isRedeemed
                                      ? Chip(
                                          label: const Text('Redeemed'),
                                          backgroundColor: AppTheme.specNavy.withValues(alpha: 0.1),
                                        )
                                      : e.canRedeem
                                          ? AppPrimaryButton(
                                              onPressed: () => _redeem(e),
                                              expanded: false,
                                              child: const Text('Redeem'),
                                            )
                                          : Text(
                                              '${e.currentPunches}/${e.punchesRequired}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                ),
                              )),
                        ],
                      ),
                    ),
    );
  }
}
