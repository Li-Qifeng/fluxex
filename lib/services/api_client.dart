import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';

/// V2EX API 底层客户端，只负责 Dio 实例和 Cookie 管理
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final CookieJar cookieJar = CookieJar();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://www.v2ex.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': 'FluxEx/0.1.12 (Flutter; Cross-platform; V2EX)',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.add(CookieManager(cookieJar));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(responseBody: true));
    }
  }

  Dio get dio => _dio;
}
