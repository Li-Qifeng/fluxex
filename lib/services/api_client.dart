import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';

/// V2EX API 底层客户端，只负责 Dio 实例和 Cookie 管理
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  final CookieJar cookieJar = CookieJar();

  String _proxyHost = '';
  int _proxyPort = 0;

  ApiClient._internal() {
    _dio = _createDio();
  }

  Dio _createDio() {
    final options = BaseOptions(
      baseUrl: 'https://www.v2ex.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'FluxEx/0.2.11 (Flutter; Cross-platform; V2EX)',
        'Accept': 'application/json',
      },
    );
    final dio = Dio(options);
    dio.interceptors.add(CookieManager(cookieJar));
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(responseBody: true));
    }
    _applyProxy(dio);
    return dio;
  }

  void _applyProxy(Dio dio) {
    if (_proxyHost.isEmpty || _proxyPort <= 0) return;
    if (dio.httpClientAdapter is IOHttpClientAdapter) {
      (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.findProxy = (uri) {
          return 'PROXY $_proxyHost:$_proxyPort';
        };
        return client;
      };
    }
  }

  /// 配置代理（空 host 和 0 端口 = 清除）
  void configureProxy(String host, int port) {
    _proxyHost = host;
    _proxyPort = port;

    // Re-create dio with new proxy
    final newDio = _createDio();
    // Copy cookies from old dio
    _dio = newDio;
  }

  Dio get dio => _dio;
}