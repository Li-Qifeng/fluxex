import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

bool _isImageUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.bmp');
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
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('复制链接'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('链接已复制')),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
