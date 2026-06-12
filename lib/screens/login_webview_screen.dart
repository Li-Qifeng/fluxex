import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_client.dart';
import '../providers/auth_provider.dart';

class LoginWebViewScreen extends ConsumerStatefulWidget {
  const LoginWebViewScreen({super.key});

  @override
  ConsumerState<LoginWebViewScreen> createState() => _LoginWebViewScreenState();
}

class _LoginWebViewScreenState extends ConsumerState<LoginWebViewScreen> {
  double _progress = 0;

  Future<String?> _extractUsernameFromPage(InAppWebViewController controller) async {
    try {
      final result = await controller.evaluateJavascript(source: '''
        (() => {
          // Strategy 1: Find avatar-linked member in top nav / sidebar
          const avatarSelectors = [
            '#Top img.avatar',
            '#Rightbar img.avatar',
            '.content img.avatar',
            'img.avatar'
          ];
          for (const sel of avatarSelectors) {
            const img = document.querySelector(sel);
            if (img) {
              const a = img.closest('a[href^="/member/"]');
              if (a) {
                const m = a.getAttribute('href').match(/\\/member\\/([^/]+)/);
                if (m) return m[1];
              }
            }
          }
          // Strategy 2: Direct link with /member/ prefix
          const links = document.querySelectorAll('a[href^="/member/"]');
          for (const a of links) {
            const href = a.getAttribute('href');
            const m = href.match(/\\/member\\/([^/]+)/);
            if (m) {
              const name = m[1];
              // Skip template literals like encodeURIComponent(memberUsername)
              if (name && name !== 'encodeURIComponent(memberUsername)') return name;
            }
          }
          return null;
        })()
      ''');
      if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
        return result.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveUsernameFromMyPage() async {
    try {
      final api = V2exApiClient();
      final dio = api.dio;
      final originalFollowRedirects = dio.options.followRedirects;
      final originalValidateStatus = dio.options.validateStatus;
      dio.options.followRedirects = false;
      dio.options.validateStatus = (status) => status != null && status < 400;
      final response = await dio.get('/my/');
      dio.options.followRedirects = originalFollowRedirects;
      dio.options.validateStatus = originalValidateStatus;
      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value('location');
        if (location != null) {
          final match = RegExp(r'/member/([^/]+)').firstMatch(location);
          if (match != null) return match.group(1);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _extractAndSaveCookie(InAppWebViewController controller) async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri('https://www.v2ex.com'));
    final a2Cookie = cookies.where((c) => c.name == 'A2').firstOrNull;
    if (a2Cookie == null || a2Cookie.value.isEmpty) return;

    // Strategy 1: Extract from current page DOM
    String? username = await _extractUsernameFromPage(controller);

    // Strategy 2: Resolve via /my/ redirect using dio
    if (username == null || username.isEmpty) {
      username = await _resolveUsernameFromMyPage();
    }

    await ref.read(authProvider.notifier).setA2Cookie(a2Cookie.value, username: username);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(username != null && username.isNotEmpty ? '登录成功: $username' : '登录成功')),
      );
      Navigator.of(context).pop(true);
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
