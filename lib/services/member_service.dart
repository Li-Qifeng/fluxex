import 'package:dio/dio.dart';
import 'api_client.dart';

class MemberService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getInfo(String username) async {
    final res = await _dio.get('/api/members/show.json', queryParameters: {'username': username});
    return res.data as Map<String, dynamic>;
  }
}
