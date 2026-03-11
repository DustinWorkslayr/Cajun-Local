import 'package:flutter/material.dart';
import 'package:cajun_local/features/news/data/models/blog_post.dart';
import 'package:cajun_local/features/admin/data/models/parish.dart';
import 'package:cajun_local/features/news/data/repositories/blog_posts_repository.dart';
import 'package:cajun_local/features/admin/data/repositories/parish_repository.dart';
import 'package:cajun_local/core/theme/theme.dart';
import 'package:cajun_local/features/admin/presentation/screens/admin_add_blog_post_screen.dart';
import 'package:cajun_local/features/admin/presentation/screens/admin_blog_detail_screen.dart';
import 'package:cajun_local/features/admin/presentation/widgets/admin_shared.dart';

class AdminBlogScreen extends StatelessWidget {
  const AdminBlogScreen({super.key, this.status, this.embeddedInShell = false});

  final String? status;
  final bool embeddedInShell;

  void _openAddPost(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminAddBlogPostScreen()));
  }

  static String _parishLabel(BlogPost p, Map<String, String> idToName) {
    if (p.isAllParishes) return 'All parishes';
    return p.parishIds!.map((id) => idToName[id] ?? id).join(', ');
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final repo = BlogPostsRepository();
    final parishRepo = ParishRepository();
    return FutureBuilder<(List<BlogPost>, List<Parish>)>(
      future: Future.wait([
        repo.listForAdmin(status: status),
        parishRepo.listParishes(),
      ]).then((r) => (r[0] as List<BlogPost>, r[1] as List<Parish>)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data?.$1 ?? [];
        final parishes = snapshot.data?.$2 ?? [];
        final idToName = {for (final x in parishes) x.id: x.name};
        if (list.isEmpty) {
          return Center(
            child: Text(
              status != null ? 'No $status posts.' : 'No blog posts.',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final p = list[index];
            final bodyPreview = p.content != null && p.content!.isNotEmpty
                ? (p.content!.length > 90 ? '${p.content!.substring(0, 90)}…' : p.content)
                : null;
            final dateStr = p.publishedAt != null
                ? '${p.publishedAt!.month}/${p.publishedAt!.day}/${p.publishedAt!.year}'
                : (p.createdAt != null ? '${p.createdAt!.month}/${p.createdAt!.day}/${p.createdAt!.year}' : null);
            final badgeList = [
              AdminBadgeData(p.status, color: p.status == 'pending' ? AppTheme.specRed : null),
              AdminBadgeData(_parishLabel(p, idToName)),
              AdminBadgeData(p.slug),
              if (dateStr != null) AdminBadgeData(dateStr),
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminListCard(
                title: p.title,
                subtitle: bodyPreview ?? 'Slug: ${p.slug}',
                badges: badgeList,
                leading: p.coverImageUrl != null && p.coverImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          p.coverImageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _leadingIcon(context),
                        ),
                      )
                    : _leadingIcon(context),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => AdminBlogDetailScreen(postId: p.id)));
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
              onPressed: () => _openAddPost(context),
              tooltip: 'Add blog post',
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(status != null ? 'Blog ($status)' : 'All blog posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add blog post',
            onPressed: () => _openAddPost(context),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  static Widget _leadingIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.specGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.article_rounded, color: AppTheme.specNavy, size: 26),
    );
  }
}
