import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:html/dom.dart' as dom;

/// 从 HTML <pre><code class="lang-xxx"> 提取语言标识
String? _extractLanguage(dom.Element codeElement) {
  for (final cls in codeElement.classes) {
    if (cls.startsWith('lang-')) return cls.substring(5);
    if (cls.startsWith('language-')) return cls.substring(9);
  }
  return null;
}

/// 递归提取 <code> 内的纯文本，保留换行（兼容 <br>）
String _extractCodeText(dom.Node node) {
  if (node is dom.Text) {
    return node.text;
  } else if (node is dom.Element) {
    if (node.localName == 'br') return '\n';
    final buffer = StringBuffer();
    for (final child in node.nodes) {
      buffer.write(_extractCodeText(child));
    }
    return buffer.toString();
  }
  return '';
}

/// HtmlWidget 的 customWidgetBuilder，用于拦截 <pre><code> 代码块并用 flutter_highlight 高亮
Widget? codeBlockWidgetBuilder(dom.Element element) {
  if (element.localName != 'pre') return null;

  final codeElement = element.children.cast<dom.Element?>().firstWhere(
        (c) => c?.localName == 'code',
        orElse: () => null,
      );
  if (codeElement == null) return null;

  final code = _extractCodeText(codeElement);
  final language = _extractLanguage(codeElement);

  return Builder(
    builder: (context) {
      final brightness = Theme.of(context).brightness;
      final isDark = brightness == Brightness.dark;

      // 代码块容器背景保持与主题协调，但内部高亮主题使用专用配色
      final bgColor = isDark ? const Color(0xff1e1e2e) : const Color(0xfff5f5f5);
      final borderColor = isDark ? const Color(0xff2a2a40) : const Color(0xffe0e0e0);
      final highlightTheme = isDark ? atomOneDarkTheme : githubTheme;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              code,
              language: language,
              theme: highlightTheme,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    },
  );
}
