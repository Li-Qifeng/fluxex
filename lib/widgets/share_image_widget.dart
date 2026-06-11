import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/topic.dart';
import '../utils/time_util.dart';

/// Theme mode for the share image.
enum ShareImageTheme { light, dark }

/// A self-contained widget that renders a styled card of a V2EX topic,
/// intended for screenshot capture via [RepaintBoundary].
class ShareImageWidget extends StatelessWidget {
  final Topic topic;
  final ShareImageTheme theme;

  /// GlobalKey used by the parent to locate the [RepaintBoundary].
  final GlobalKey boundaryKey;

  const ShareImageWidget({
    super.key,
    required this.topic,
    required this.boundaryKey,
    this.theme = ShareImageTheme.light,
  });

  // ── colour palettes ──────────────────────────────────────────────
  bool get _isDark => theme == ShareImageTheme.dark;

  Color get _bgColor => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _cardColor => _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF7F8FA);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1A1A1A);
  Color get _textSecondary => _isDark ? Colors.white70 : const Color(0xFF666666);
  Color get _accentColor => _isDark ? const Color(0xFF64B5F6) : const Color(0xFF1A73E8);
  Color get _borderColor => _isDark ? Colors.white12 : Colors.black12;
  Color get _footerBg => _isDark ? const Color(0xFF252525) : const Color(0xFFECEFF1);

  // ── helpers ──────────────────────────────────────────────────────
  String _stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    final doc = html_parser.parse(html);
    return doc.body?.text.trim() ?? '';
  }

  String _snippet({int maxLen = 200}) {
    final text = _stripHtml(topic.contentRendered ?? topic.content);
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}…';
  }

  String _formatDate() => formatAbsoluteTime(topic.created);

  // ── build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 600,
        color: _bgColor,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo / branding ──
            Row(
              children: [
                Text(
                  'V2EX',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'via FluxEx',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Title ──
            Text(
              topic.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.45,
                color: _textPrimary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            // ── Author / date / node row ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 15, color: _textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    topic.member.username,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.schedule_rounded, size: 14, color: _textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(),
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      topic.node.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Content snippet ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderColor, width: 0.5),
              ),
              child: Text(
                _snippet(),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: _textPrimary.withValues(alpha: 0.88),
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),

            // ── Footer: topic URL + decorative "QR" grid ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _footerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Decorative QR-like grid
                  _buildQrDecoration(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '扫码或访问链接查看完整内容',
                          style: TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'https://www.v2ex.com/t/${topic.id}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: _textSecondary),
                      const SizedBox(height: 2),
                      Text(
                        '${topic.replies} 回复',
                        style:
                            TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a small decorative QR-code-like grid pattern.
  Widget _buildQrDecoration() {
    // 7×7 grid with a deterministic pattern based on topic id
    const size = 48.0;
    const cellCount = 7;
    final cells = <bool>[];
    var hash = topic.id;
    for (var i = 0; i < cellCount * cellCount; i++) {
      hash = (hash * 1103515245 + 12345) & 0x7fffffff;
      cells.add(hash % 3 != 0);
    }
    // Force the corners to be filled (mimic QR finder patterns)
    for (final offset in [0, 1, 2, 7, 14, 8, 15, 16]) {
      if (offset < cells.length) cells[offset] = true;
    }
    for (final offset in [48, 49, 50, 41, 34, 42, 35, 36]) {
      if (offset < cells.length) cells[offset] = true;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      padding: const EdgeInsets.all(3),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cellCount,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: cells.length,
        itemBuilder: (_, i) {
          return Container(
            decoration: BoxDecoration(
              color: cells[i] ? _textPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        },
      ),
    );
  }
}
