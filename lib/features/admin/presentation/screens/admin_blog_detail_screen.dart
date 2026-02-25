import 'package:flutter/material.dart';
import 'package:my_app/core/data/app_data_scope.dart';
import 'package:my_app/core/data/models/blog_post.dart';
import 'package:my_app/core/data/repositories/audit_log_repository.dart';
import 'package:my_app/core/data/repositories/blog_posts_repository.dart';
import 'package:my_app/features/admin/presentation/screens/admin_add_blog_post_screen.dart';

class AdminBlogDetailScreen extends StatefulWidget {
  const AdminBlogDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<AdminBlogDetailScreen> createState() => _AdminBlogDetailScreenState();
}

class _AdminBlogDetailScreenState extends State<AdminBlogDetailScreen> {
  BlogPost? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BlogPostsRepository();
    final p = await repo.getById(widget.postId);
    if (mounted) {
      setState(() {
        _post = p;
        _loading = false;
        if (p == null) _error = 'Post not found';
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final repo = BlogPostsRepository();
    final uid = AppDataScope.of(context).authRepository.currentUserId;
    await repo.updateStatus(widget.postId, status, approvedBy: uid);
    AuditLogRepository().insert(
      action: status == 'approved' ? 'blog_approved' : 'blog_rejected',
      userId: uid,
      targetTable: 'blog_posts',
      targetId: widget.postId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status set to $status')),
      );
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
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => AdminAddBlogPostScreen(post: _post),
                  ),
                );
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
                      _DetailRow(label: 'Title', value: _post!.title),
                      _DetailRow(label: 'Slug', value: _post!.slug),
                      if (_post!.authorId != null) _DetailRow(label: 'Author ID', value: _post!.authorId!),
                      if (_post!.content != null) _DetailRow(label: 'Content', value: _post!.content!.length > 200 ? '${_post!.content!.substring(0, 200)}...' : _post!.content!),
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
