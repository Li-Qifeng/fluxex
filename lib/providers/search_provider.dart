import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class SearchResult {
  final int id;
  final String title;
  final String content;
  final String member;
  final int node;
  final int replies;
  final String created;

  SearchResult({
    required this.id,
    required this.title,
    required this.content,
    required this.member,
    required this.node,
    required this.replies,
    required this.created,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final s = json['_source'] as Map<String, dynamic>;
    return SearchResult(
      id: s['id'] as int,
      title: s['title'] as String,
      content: s['content'] as String? ?? '',
      member: s['member'] as String? ?? '',
      node: s['node'] as int? ?? 0,
      replies: s['replies'] as int? ?? 0,
      created: s['created'] as String? ?? '',
    );
  }
}

final _searchDio = Dio(BaseOptions(
  baseUrl: 'https://www.sov2ex.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

Future<List<SearchResult>> searchSov2ex(String query, {int from = 0, int size = 20}) async {
  final response = await _searchDio.get('/api/search', queryParameters: {
    'q': query,
    'from': from,
    'size': size,
  });
  if (response.data is Map) {
    final hits = (response.data as Map)['hits'] as List<dynamic>? ?? [];
    return hits.map((e) => SearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }
  throw Exception('Invalid search response');
}

final searchProvider = FutureProvider.family<List<SearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return searchSov2ex(query.trim());
});
