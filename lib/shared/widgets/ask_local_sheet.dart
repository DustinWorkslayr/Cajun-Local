import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/shared/widgets/app_buttons.dart';
import 'package:my_app/core/data/mock_data.dart';
import 'package:my_app/core/data/services/ask_local_service.dart';
import 'package:my_app/core/preferences/user_parish_preferences.dart';
import 'package:my_app/core/theme/theme.dart';
import 'package:my_app/features/listing/presentation/screens/listing_detail_screen.dart';

/// Message in the Ask Local conversation (user or AI). AI messages may include listing IDs to show as cards.
class _Message {
  const _Message({
    required this.isUser,
    required this.text,
    this.listingIds = const [],
  });
  final bool isUser;
  final String text;
  final List<String> listingIds;
}

/// Regex to parse [LISTINGS:id1,id2,...] at end of AI reply. Captures comma-separated IDs.
final _listingsPattern = RegExp(r'\[LISTINGS:([^\]]*)\]');

/// Strips the [LISTINGS:...] line from [text] and returns (displayText, listOfIds).
(String, List<String>) parseListingsFromReply(String text) {
  final match = _listingsPattern.firstMatch(text);
  if (match == null) return (text, const []);
  final idsStr = match.group(1)?.trim() ?? '';
  final ids = idsStr.isEmpty
      ? <String>[]
      : idsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final displayText = text.replaceAll(_listingsPattern, '').replaceAll(RegExp(r'\n\s*$'), '').trim();
  return (displayText, ids);
}

/// Shows the Ask Local conversation bottom sheet.
/// [accessToken] must be the current user's JWT (required for API).
void showAskLocalSheet(BuildContext context, {required String accessToken}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.specWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AskLocalSheet(accessToken: accessToken),
  );
}

class _AskLocalSheet extends StatefulWidget {
  const _AskLocalSheet({required this.accessToken});

  final String accessToken;

  @override
  State<_AskLocalSheet> createState() => _AskLocalSheetState();
}

class _AskLocalSheetState extends State<_AskLocalSheet> {
  final _messages = <_Message>[];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  String? _error;
  final _service = AskLocalService();

  // Form-style state (when no messages yet)
  String _formType = '';
  Set<String> _formParishIds = {};
  List<MockParish> _formParishes = [];
  final _formExtraController = TextEditingController();
  bool _formParishesLoaded = false;
  /// Preferred parish IDs used for the last/current conversation (for follow-up sends).
  List<String>? _lastPreferredParishIds;

  static const _typeOptions = [
    ('Food & dining', 'Food & dining'),
    ('Shopping', 'Shopping'),
    ('Services', 'Services'),
    ('Deals', 'Deals'),
    ('Events', 'Events'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferredParishes();
  }

  Future<void> _loadPreferredParishes() async {
    try {
      final ds = AppDataScope.of(context).dataSource;
      final ids = await UserParishPreferences.getPreferredParishIds();
      final list = await ds.getParishes();
      if (!mounted) return;
      setState(() {
        _formParishIds = Set.from(ids);
        _formParishes = list;
        _formParishesLoaded = true;
      });
    } catch (_) {
      final ids = await UserParishPreferences.getPreferredParishIds();
      if (!mounted) return;
      setState(() {
        _formParishIds = Set.from(ids);
        _formParishes = List<MockParish>.from(MockData.parishes);
        _formParishesLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _formExtraController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendFromForm() async {
    final type = _formType.trim();
    if (type.isEmpty) return;
    final areas = _formParishIds.isEmpty
        ? 'my preferred areas'
        : _formParishes
            .where((p) => _formParishIds.contains(p.id))
            .map((p) => p.name)
            .join(', ');
    final extra = _formExtraController.text.trim();
    final question = extra.isEmpty
        ? "I'm looking for $type in $areas."
        : "I'm looking for $type in $areas. $extra";
    final ids = _formParishIds.isEmpty ? null : _formParishIds.toList();
    _lastPreferredParishIds = ids;
    await _send(question, preferredParishIds: ids);
  }

  Future<void> _send(String question, {List<String>? preferredParishIds}) async {
    final q = question.trim();
    if (q.isEmpty || _loading) return;
    setState(() {
      _error = null;
      _messages.add(_Message(isUser: true, text: q));
      _loading = true;
    });
    _inputController.clear();
    _formExtraController.clear();
    _scrollToEnd();

    final parishIds = preferredParishIds ?? _lastPreferredParishIds;
    final result = await _service.ask(
      question: q,
      accessToken: widget.accessToken,
      preferredParishIds: parishIds,
    );

    if (!mounted) return;

    if (result is AskLocalFailure) {
      setState(() {
        _loading = false;
        _error = result.message;
        if (result.code == 'subscription_required') {
          _error = '${result.message} Upgrade to Cajun+ Membership (\$2.99) or Pro to use Ask Local.';
        }
      });
      return;
    }

    final stream = (result as AskLocalStream).stream;
    final buffer = StringBuffer();
    setState(() {
      _messages.add(_Message(isUser: false, text: ''));
      _loading = false;
    });

    await for (final chunk in stream) {
      if (!mounted) return;
      buffer.write(chunk);
      final (displayText, ids) = parseListingsFromReply(buffer.toString());
      setState(() {
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages[_messages.length - 1] = _Message(isUser: false, text: displayText, listingIds: ids);
        }
      });
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    final sub = nav.withValues(alpha: 0.7);
    final height = MediaQuery.sizeOf(context).height;
    final sheetHeight = (height * 0.6).clamp(400.0, height - 100);
    final showForm = _messages.isEmpty && !_loading;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: AppTheme.specGold, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask Local',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: nav,
                        ),
                      ),
                      Text(
                        'Tell us what you\'re looking for—we\'ll search your preferred areas.',
                        style: theme.textTheme.bodySmall?.copyWith(color: sub),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: nav,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Material(
                color: AppTheme.specRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppTheme.specRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.specRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: showForm
                ? _buildForm(theme, nav, sub)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MessageBubble(
                          message: msg,
                          theme: theme,
                          nav: nav,
                        ),
                      );
                    },
                  ),
          ),
          if (!showForm)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.paddingOf(context).bottom),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Ask a follow-up…',
                        hintStyle: TextStyle(color: sub),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: nav.withValues(alpha: 0.3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _loading ? null : (_) => _send(_inputController.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading
                        ? null
                        : () => _send(_inputController.text),
                    icon: _loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.specWhite),
                          )
                        : const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.specNavy,
                      foregroundColor: AppTheme.specWhite,
                    ),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme, Color nav, Color sub) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What are you looking for?',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: nav),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _typeOptions.map((t) {
              final selected = _formType == t.$1;
              return FilterChip(
                label: Text(t.$1, style: TextStyle(fontSize: 13, color: nav)),
                selected: selected,
                onSelected: (v) => setState(() => _formType = v ? t.$1 : ''),
                backgroundColor: AppTheme.specOffWhite,
                selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                side: BorderSide(
                  color: selected ? AppTheme.specGold : nav.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Which area?',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: nav),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll only show listings in these parishes.',
            style: theme.textTheme.bodySmall?.copyWith(color: sub),
          ),
          const SizedBox(height: 8),
          if (!_formParishesLoaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formParishes.map((p) {
                final selected = _formParishIds.contains(p.id);
                return FilterChip(
                  label: Text(p.name, style: TextStyle(fontSize: 13, color: nav)),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _formParishIds = Set.from(_formParishIds)..add(p.id);
                    } else {
                      _formParishIds = Set.from(_formParishIds)..remove(p.id);
                    }
                  }),
                  backgroundColor: AppTheme.specOffWhite,
                  selectedColor: AppTheme.specGold.withValues(alpha: 0.3),
                  side: BorderSide(
                    color: selected ? AppTheme.specGold : nav.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          Text(
            'Anything else? (optional)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: nav),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _formExtraController,
            decoration: InputDecoration(
              hintText: 'e.g. kid-friendly, under \$20, open now',
              hintStyle: TextStyle(color: sub),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: nav.withValues(alpha: 0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 24),
          AppSecondaryButton(
            onPressed: _formType.isEmpty || _loading
                ? null
                : () => _sendFromForm(),
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: const Text('Find for me'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.theme,
    required this.nav,
  });

  final _Message message;
  final ThemeData theme;
  final Color nav;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!message.isUser)
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.specGold.withValues(alpha: 0.3),
            child: Icon(Icons.support_agent_rounded, size: 16, color: nav),
          ),
        if (!message.isUser) const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppTheme.specNavy.withValues(alpha: 0.12)
                      : AppTheme.specOffWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.text.isEmpty ? '…' : message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: nav,
                    height: 1.4,
                  ),
                ),
              ),
              if (!message.isUser && message.listingIds.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ListingCardsRow(listingIds: message.listingIds),
              ],
            ],
          ),
        ),
        if (message.isUser) const SizedBox(width: 8),
        if (message.isUser)
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.specGold.withValues(alpha: 0.3),
            child: Icon(Icons.person_rounded, size: 16, color: nav),
          ),
      ],
    );
  }
}

class _ListingCardsRow extends StatelessWidget {
  const _ListingCardsRow({required this.listingIds});

  final List<String> listingIds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: listingIds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _CompactListingCard(listingId: listingIds[index]),
      ),
    );
  }
}

class _CompactListingCard extends StatelessWidget {
  const _CompactListingCard({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = AppTheme.specNavy;
    return FutureBuilder<MockListing?>(
      future: AppDataScope.of(context).dataSource.getListingById(listingId),
      builder: (context, snapshot) {
        final listing = snapshot.data;
        if (listing == null) {
          return SizedBox(
            width: 160,
            child: Card(
              elevation: 0,
              color: AppTheme.specOffWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          );
        }
        return SizedBox(
          width: 180,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ListingDetailScreen(listingId: listing.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.specWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: nav.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      listing.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: nav,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.tagline,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'View',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.specGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.specGold),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
