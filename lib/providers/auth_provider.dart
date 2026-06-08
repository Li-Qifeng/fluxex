import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'api_client.dart';

const _a2Key = 'v2ex_a2_cookie';

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
  AuthNotifier() : super(AuthState(isLoggedIn: false)) {
    _loadPersistedCookie();
  }

  Future<void> _loadPersistedCookie() async {
    final prefs = await SharedPreferences.getInstance();
    final a2 = prefs.getString(_a2Key);
    if (a2 != null && a2.isNotEmpty) {
      await _injectA2(a2);
      state = state.copyWith(isLoggedIn: true);
    }
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

  Future<void> setA2Cookie(String a2Value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_a2Key, a2Value);
    await _injectA2(a2Value);
    state = state.copyWith(isLoggedIn: true);
  }

  Future<void> clearA2Cookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_a2Key);
  }

  Future<void> logout() async {
    final api = V2exApiClient();
    await api.dio.interceptors
        .whereType<CookieManager>()
        .first
        .cookieJar
        .delete(Uri.parse('https://www.v2ex.com'));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_a2Key);
    state = AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
