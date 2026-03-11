import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// One editable block in the blog body (paragraph, heading, list).
/// Serializes to/from HTML for storage; editor shows rich blocks, not raw HTML.
class BlogContentBlock {
  const BlogContentBlock({
    required this.type,
    this.text,
    this.items,
  }) : assert(
          type == 'ul' || type == 'ol' ? items != null : text != null,
          'List blocks need items; others need text',
        );

  /// 'paragraph' | 'h2' | 'h3' | 'ul' | 'ol'
  final String type;
  /// For paragraph, h2, h3
  final String? text;
  /// For ul, ol: list item lines
  final List<String>? items;

  static String _escapeHtml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  /// Serialize blocks to HTML (for saving to DB).
  static String toHtml(List<BlogContentBlock> blocks) {
    final buf = StringBuffer();
    for (final b in blocks) {
      switch (b.type) {
        case 'paragraph':
          buf.write('<p>');
          buf.write(_escapeHtml(b.text ?? ''));
          buf.write('</p>\n');
          break;
        case 'h2':
          buf.write('<h2>');
          buf.write(_escapeHtml(b.text ?? ''));
          buf.write('</h2>\n');
          break;
        case 'h3':
          buf.write('<h3>');
          buf.write(_escapeHtml(b.text ?? ''));
          buf.write('</h3>\n');
          break;
        case 'ul':
          buf.write('<ul>\n');
          for (final item in b.items ?? []) {
            buf.write('<li>');
            buf.write(_escapeHtml(item));
            buf.write('</li>\n');
          }
          buf.write('</ul>\n');
          break;
        case 'ol':
          buf.write('<ol>\n');
          for (final item in b.items ?? []) {
            buf.write('<li>');
            buf.write(_escapeHtml(item));
            buf.write('</li>\n');
          }
          buf.write('</ol>\n');
          break;
        default:
          buf.write('<p>');
          buf.write(_escapeHtml(b.text ?? ''));
          buf.write('</p>\n');
      }
    }
    return buf.toString().trim();
  }

  static String _textFromNode(dom.Node node) {
    if (node is dom.Text) return node.text;
    if (node is dom.Element) {
      if (node.localName == 'br') return '\n';
      return node.nodes.map(_textFromNode).join();
    }
    return '';
  }

  /// Parse stored HTML back into blocks (for editing).
  static List<BlogContentBlock> fromHtml(String? html) {
    if (html == null || html.trim().isEmpty) {
      return [const BlogContentBlock(type: 'paragraph', text: '')];
    }
    List<BlogContentBlock> blocks;
    try {
      final fragment = html_parser.parseFragment(html);
      blocks = _parseFragmentNodes(fragment);
    } catch (_) {
      return [const BlogContentBlock(type: 'paragraph', text: '')];
    }
    if (blocks.isEmpty) {
      return [const BlogContentBlock(type: 'paragraph', text: '')];
    }
    return blocks;
  }

  static List<BlogContentBlock> _parseFragmentNodes(dom.DocumentFragment fragment) {
    final blocks = <BlogContentBlock>[];
    final nodes = fragment.nodes;
    void walk(dom.Node node) {
      if (node is dom.Element) {
        final tag = node.localName?.toLowerCase();
        final text = _textFromNode(node).trim();
        switch (tag) {
          case 'p':
            blocks.add(BlogContentBlock(type: 'paragraph', text: text));
            return;
          case 'h2':
            blocks.add(BlogContentBlock(type: 'h2', text: text));
            return;
          case 'h3':
            blocks.add(BlogContentBlock(type: 'h3', text: text));
            return;
          case 'ul':
            final items = node.querySelectorAll('li').map((e) => _textFromNode(e).trim()).where((s) => s.isNotEmpty).toList();
            blocks.add(BlogContentBlock(type: 'ul', items: items.isEmpty ? [''] : items));
            return;
          case 'ol':
            final items = node.querySelectorAll('li').map((e) => _textFromNode(e).trim()).where((s) => s.isNotEmpty).toList();
            blocks.add(BlogContentBlock(type: 'ol', items: items.isEmpty ? [''] : items));
            return;
        }
      }
      for (final child in node.nodes) {
        walk(child);
      }
    }
    for (final child in nodes) {
      walk(child);
    }
    return blocks;
  }
}
