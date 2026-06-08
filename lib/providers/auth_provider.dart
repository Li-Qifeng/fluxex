import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'api_client.dart';

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
  AuthNotifier() : super(AuthState(isLoggedIn: false));

  Future<void> setA2Cookie(String a2Value) async {
    final api = V2exApiClient();
    final cookie = Cookie('A2', a2Value)
      ..domain = '.v2ex.com'
      ..path = '/';
    await api.dio.interceptors
        .whereType<CookieManager>()
        .first
        .cookieJar
        .saveFromResponse(Uri.parse('https://www.v2ex.com'), [cookie]);
    state = state.copyWith(isLoggedIn: true);
  }

  Future<void> logout() async {
    final api = V2exApiClient();
    await api.dio.interceptors
        .whereType<CookieManager>()
        .first
        .cookieJar
        .delete(Uri.parse('https://www.v2ex.com'));
    state = AuthState(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
