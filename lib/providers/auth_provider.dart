import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'api_client.dart';

const _a2Key = 'v2ex_a2_cookie';
const _usernameKey = 'v2ex_username';

class AuthState {
  final String? username;
  final bool isLoggedIn;

  AuthState({this.username, required this.isLoggedIn});

  AuthState copyWith({String? username, bool? isLoggedIn}) {
    return AuthState(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _secure = const FlutterSecureStorage();

  AuthNotifier() : super(AuthState(isLoggedIn: false)) {
    _loadPersistedCookie();
  }

  Future<void> _loadPersistedCookie() async {
    final a2 = await _secure.read(key: _a2Key);
    var username = await _secure.read(key: _usernameKey);
    if (a2 != null && a2.isNotEmpty) {
      await _injectA2(a2);
      // If username missing but cookie valid, try resolving from /my/ redirect
      if (username == null || username.isEmpty) {
        username = await _resolveUsernameFromMyPage();
        if (username != null && username.isNotEmpty) {
          await _secure.write(key: _usernameKey, value: username);
        }
      }
      state = state.copyWith(isLoggedIn: true, username: username);
    }
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

  Future<void> _injectA2(String a2Value) async {
    final api = V2exApiClient();
    final cookie = Cookie('A2', a2Value)
      ..domain = '.v2ex.com'
      ..path = '/';
    await api.dio.interceptors
        .whereType<CookieManager>()
        .first
        .cookieJar
        .saveFromResponse(Uri.parse('https://www.v2ex.com'), [cookie]);
  }

  Future<void> setA2Cookie(String a2Value, {String? username}) async {
    await _secure.write(key: _a2Key, value: a2Value);
    if (username != null && username.isNotEmpty) {
      await _secure.write(key: _usernameKey, value: username);
    }
    await _injectA2(a2Value);
    state = state.copyWith(isLoggedIn: true, username: username);
  }

  Future<void> clearA2Cookie() async {
    await _secure.delete(key: _a2Key);
    await _secure.delete(key: _usernameKey);
  }

  Future<void> logout() async {
    final api = V2exApiClient();
    await api.dio.interceptors
        .whereType<CookieManager>()
        .first
        .cookieJar
        .delete(Uri.parse('https://www.v2ex.com'));
    await _secure.delete(key: _a2Key);
    await _secure.delete(key: _usernameKey);
    state = AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
