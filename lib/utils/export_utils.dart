import 'package:html/parser.dart' as html_parser;
import '../models/reply.dart';
import '../models/topic.dart';
import 'time_util.dart';

/// Strip HTML tags, returning plain text.
String _stripHtml(String html) {
  final doc = html_parser.parse(html);
  return doc.body?.text.trim() ?? '';
}

/// Export a topic and its replies as a Markdown string.
String exportAsMarkdown(Topic topic, List<Reply> replies) {
  final sb = StringBuffer();
  final date = formatAbsoluteTime(topic.created);

  sb.writeln('# ${topic.title}');
  sb.writeln();
  sb.writeln('- **作者**: ${topic.member.username}');
  sb.writeln('- **节点**: ${topic.node.title}');
  sb.writeln('- **时间**: $date');
  sb.writeln('- **回复数**: ${topic.replies}');
  sb.writeln('- **链接**: https://www.v2ex.com/t/${topic.id}');
  sb.writeln();
  sb.writeln('---');
  sb.writeln();

  final content = topic.contentRendered != null
      ? _stripHtml(topic.contentRendered!)
      : (topic.content ?? '');
  if (content.isNotEmpty) {
    sb.writeln(content);
    sb.writeln();
  }

  if (replies.isNotEmpty) {
    sb.writeln('---');
    sb.writeln();
    sb.writeln('## 回复');
    sb.writeln();
    for (var i = 0; i < replies.length; i++) {
      final r = replies[i];
      final floor = i + 1;
      final rDate = formatAbsoluteTime(r.created);
      final rContent = r.contentRendered != null
          ? _stripHtml(r.contentRendered!)
          : (r.content ?? '');
      sb.writeln('### #$floor @${r.member.username}  ($rDate)');
      sb.writeln();
      sb.writeln(rContent);
      sb.writeln();
    }
  }

  return sb.toString();
}

/// Export a topic and its replies as a standalone HTML document with inline CSS.
String exportAsHtml(Topic topic, List<Reply> replies) {
  final date = formatAbsoluteTime(topic.created);
  final content = topic.contentRendered ?? topic.content ?? '';

  final repliesHtml = StringBuffer();
  for (var i = 0; i < replies.length; i++) {
    final r = replies[i];
    final floor = i + 1;
    final rDate = formatAbsoluteTime(r.created);
    final rContent = r.contentRendered ?? r.content ?? '';
    repliesHtml.writeln('''
      <div class="reply">
        <div class="reply-header">
          <span class="floor">#$floor</span>
          <span class="author">@${_escapeHtml(r.member.username)}</span>
          <span class="date">$rDate</span>
        </div>
        <div class="reply-body">$rContent</div>
      </div>''');
  }

  return '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${_escapeHtml(topic.title)}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      line-height: 1.7;
      color: #1a1a1a;
      background: #f8f9fa;
      padding: 24px 16px;
    }
    .container { max-width: 720px; margin: 0 auto; }
    h1 {
      font-size: 22px;
      font-weight: 600;
      margin-bottom: 16px;
      line-height: 1.4;
    }
    .meta {
      font-size: 14px;
      color: #666;
      margin-bottom: 20px;
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
    }
    .meta span { display: inline-flex; align-items: center; gap: 4px; }
    .content {
      font-size: 15px;
      background: #fff;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 24px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.06);
    }
    .content img { max-width: 100%; height: auto; border-radius: 4px; }
    .content a { color: #1a73e8; text-decoration: none; }
    .content a:hover { text-decoration: underline; }
    .content pre, .content code {
      background: #f0f0f0;
      border-radius: 4px;
      font-family: "SF Mono", Monaco, "Courier New", monospace;
      font-size: 13px;
    }
    .content pre { padding: 12px; overflow-x: auto; }
    .content code { padding: 2px 4px; }
    .content blockquote {
      border-left: 3px solid #d0d0d0;
      padding-left: 12px;
      color: #555;
      margin: 8px 0;
    }
    .replies-title {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 12px;
    }
    .reply {
      background: #fff;
      border-radius: 8px;
      padding: 14px 18px;
      margin-bottom: 10px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.06);
    }
    .reply-header {
      font-size: 13px;
      color: #888;
      margin-bottom: 6px;
      display: flex;
      gap: 8px;
      align-items: center;
    }
    .floor { font-weight: 700; color: #555; }
    .author { font-weight: 600; color: #333; }
    .reply-body { font-size: 14px; line-height: 1.6; }
    .reply-body img { max-width: 100%; height: auto; }
    .reply-body a { color: #1a73e8; text-decoration: none; }
    .footer {
      text-align: center;
      font-size: 12px;
      color: #aaa;
      margin-top: 32px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>${_escapeHtml(topic.title)}</h1>
    <div class="meta">
      <span>👤 ${_escapeHtml(topic.member.username)}</span>
      <span>📂 ${_escapeHtml(topic.node.title)}</span>
      <span>📅 $date</span>
      <span>💬 ${topic.replies} 回复</span>
    </div>
    <div class="content">$content</div>
    ${replies.isNotEmpty ? '<h2 class="replies-title">回复 (${replies.length})</h2>' : ''}
    $repliesHtml
    <div class="footer">
      导出自 FluxEx · ${DateTime.now().toIso8601String().substring(0, 10)}
    </div>
  </div>
</body>
</html>''';
}

String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
