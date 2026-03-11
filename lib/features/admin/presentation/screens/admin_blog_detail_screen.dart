import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cajun_local/features/auth/presentation/controllers/auth_controller.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/features/admin/data/models/parish.dart';
import 'package:cajun_local/features/admin/data/repositories/audit_log_repository.dart';
import 'package:cajun_local/features/news/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/features/admin/data/repositories/parish_repository.dart';
import 'package:cajun_local/features/admin/presentation/screens/admin_add_blog_post_screen.dart';

class AdminBlogDetailScreen extends ConsumerStatefulWidget {
  const AdminBlogDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<AdminBlogDetailScreen> createState() => _AdminBlogDetailScreenState();
}

class _AdminBlogDetailScreenState extends ConsumerState<AdminBlogDetailScreen> {
  BlogPost? _post;
  List<Parish> _parishes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BlogPostsRepository();
    final parishRepo = ParishRepository();
    final results = await Future.wait([repo.getById(widget.postId), parishRepo.listParishes()]);
    final p = results[0] as BlogPost?;
    final parishes = results[1] as List<Parish>;
    if (mounted) {
      setState(() {
        _post = p;
        _parishes = parishes;
        _loading = false;
        if (p == null) _error = 'Post not found';
      });
    }
  }

  String _parishLabel(BlogPost post) {
    if (post.isAllParishes) return 'All parishes';
    final idToName = {for (final x in _parishes) x.id: x.name};
    return post.parishIds!.map((id) => idToName[id] ?? id).join(', ');
  }

  Future<void> _updateStatus(String status) async {
    final repo = BlogPostsRepository();
    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    await repo.updateStatus(widget.postId, status, approvedBy: uid);
    AuditLogRepository().insert(
      action: status == 'approved' ? 'blog_approved' : 'blog_rejected',
      userId: uid,
      targetTable: 'blog_posts',
      targetId: widget.postId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status set to $status')));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_post?.title ?? 'Blog post'),
        actions: [
          if (_post != null)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
              onPressed: () async {
                final ok = await Navigator.of(
                  context,
                ).push<bool>(MaterialPageRoute<bool>(builder: (_) => AdminAddBlogPostScreen(post: _post)));
                if (ok == true && mounted) _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: theme.textTheme.bodyLarge))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailRow(label: 'Status', value: _post!.status),
                  _DetailRow(label: 'Parish visibility', value: _parishLabel(_post!)),
                  _DetailRow(label: 'Title', value: _post!.title),
                  _DetailRow(label: 'Slug', value: _post!.slug),
                  if (_post!.authorId != null) _DetailRow(label: 'Author ID', value: _post!.authorId!),
                  if (_post!.content != null)
                    _DetailRow(
                      label: 'Content',
                      value: _post!.content!.length > 200 ? '${_post!.content!.substring(0, 200)}...' : _post!.content!,
                    ),
                  const SizedBox(height: 24),
                  if (_post!.status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _updateStatus('approved'),
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateStatus('rejected'),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            label: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
