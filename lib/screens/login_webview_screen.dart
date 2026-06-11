import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginWebViewScreen extends ConsumerStatefulWidget {
  const LoginWebViewScreen({super.key});

  @override
  ConsumerState<LoginWebViewScreen> createState() => _LoginWebViewScreenState();
}

class _LoginWebViewScreenState extends ConsumerState<LoginWebViewScreen> {
  double _progress = 0;

  Future<void> _extractAndSaveCookie(InAppWebViewController controller) async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri('https://www.v2ex.com'));
    final a2Cookie = cookies.where((c) => c.name == 'A2').firstOrNull;
    if (a2Cookie != null && a2Cookie.value.isNotEmpty) {
      // 通过 JS 提取当前登录用户名
      String? username;
      try {
        final result = await controller.evaluateJavascript(source: '''
          (() => {
            const a = document.querySelector('a[href^="/member/"]');
            if (a) {
              const m = a.getAttribute('href').match(/\/member\/([^/]+)/);
              return m ? m[1] : null;
            }
            return null;
          })()
        ''');
        if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
          username = result.toString();
        }
      } catch (_) {}
      await ref.read(authProvider.notifier).setA2Cookie(a2Cookie.value, username: username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(username != null ? '登录成功: $username' : '登录成功')),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录 V2EX'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://www.v2ex.com/signin'),
              ),
              initialSettings: InAppWebViewSettings(
                userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
              ),
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100);
              },
              onLoadStop: (controller, url) async {
                final uri = url?.uriValue;
                if (uri == null) return;
                // 登录成功后通常会跳转到首页或其他页面
                if (uri.host == 'www.v2ex.com' && !uri.path.contains('/signin')) {
                  await _extractAndSaveCookie(controller);
                }
              },
              onUpdateVisitedHistory: (controller, url, isReload) async {
                final uri = url?.uriValue;
                if (uri == null) return;
                if (uri.host == 'www.v2ex.com' && !uri.path.contains('/signin')) {
                  await _extractAndSaveCookie(controller);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
