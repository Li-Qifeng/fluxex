import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_toast.dart';
import '../providers/settings_provider.dart';

bool _isImageUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp');
}

/// 识别 v2ex 内部链接并自动路由，否则弹出外部链接菜单
Future<void> handleTapUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final host = uri.host.toLowerCase();
  final isV2ex = host.isEmpty ||
      host == 'v2ex.com' ||
      host == 'www.v2ex.com' ||
      host.endsWith('.v2ex.com');

  if (isV2ex) {
    final path = uri.path;
    // /t/123456 → /topic/123456
    final topicMatch = RegExp(r'^/t/(\d+)').firstMatch(path);
    if (topicMatch != null) {
      final id = topicMatch.group(1)!;
      if (context.mounted) {
        context.push('/topic/$id');
      }
      return;
    }
    // /member/xxx → /member/xxx
    final memberMatch = RegExp(r'^/member/([^/]+)').firstMatch(path);
    if (memberMatch != null) {
      final username = Uri.decodeComponent(memberMatch.group(1)!);
      if (context.mounted) {
        context.push('/member/$username');
      }
      return;
    }
    // /go/xxx → /node/xxx
    final nodeMatch = RegExp(r'^/go/([^/]+)').firstMatch(path);
    if (nodeMatch != null) {
      final name = Uri.decodeComponent(nodeMatch.group(1)!);
      if (context.mounted) {
        context.push('/node/$name');
      }
      return;
    }
  }

  // 非内部链接：弹出操作菜单
  if (context.mounted) {
    await showUrlOptions(context, url);
  }
}

Future<void> showUrlOptions(BuildContext context, String url) async {
  final isImage = _isImageUrl(url);
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              isImage ? '图片操作' : '链接操作',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_browser),
            title: Text(isImage ? '浏览器打开图片' : '浏览器打开'),
            onTap: () async {
              Navigator.pop(context);
              await _launchExternalUrl(context, url);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('复制链接'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              AppToast.info(context, '链接已复制');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// Launch an external URL, showing a confirmation dialog first if needed.
Future<void> _launchExternalUrl(BuildContext context, String url) async {
  final container = ProviderScope.containerOf(context);
  final settings = container.read(settingsProvider);

  if (!settings.skipExternalLinkConfirm) {
    final proceed = await _showExternalLinkConfirmDialog(context, url);
    if (proceed != true) return;
  }

  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Show a confirmation dialog for opening an external URL.
/// Returns true if user confirms, false/null otherwise.
/// Optionally lets user check "Don't ask again".
Future<bool?> _showExternalLinkConfirmDialog(
    BuildContext context, String url) async {
  bool dontAskAgain = false;

  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('打开外部链接'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('即将在浏览器中打开以下链接：'),
                const SizedBox(height: 8),
                Text(
                  url,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: dontAskAgain,
                      onChanged: (value) {
                        setState(() {
                          dontAskAgain = value ?? false;
                        });
                      },
                    ),
                    const Text('不再询问'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  if (dontAskAgain) {
                    final container = ProviderScope.containerOf(ctx);
                    await container
                        .read(settingsProvider.notifier)
                        .setSkipExternalLinkConfirm(true);
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('打开'),
              ),
            ],
          );
        },
      );
    },
  );
}
