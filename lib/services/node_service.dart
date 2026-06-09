import 'package:dio/dio.dart';
import 'api_client.dart';

class NodeService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getInfo(String name) async {
    final res = await _dio.get('/api/nodes/show.json', queryParameters: {'name': name});
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAll() async {
    final res = await _dio.get('/api/nodes/all.json');
    return res.data as List<dynamic>;
  }
}
