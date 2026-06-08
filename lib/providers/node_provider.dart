import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node.dart';
import '../models/topic.dart';
import 'api_client.dart';

final allNodesProvider = FutureProvider<List<Node>>((ref) async {
  final api = V2exApiClient();
  final data = await api.getAllNodes();
  return data.map((e) => Node.fromJson(e as Map<String, dynamic>)).toList();
});

final nodeDetailProvider = FutureProvider.family<Node, String>((ref, name) async {
  final api = V2exApiClient();
  final data = await api.getNodeInfoByName(name);
  return Node.fromJson(data);
});

class PaginatedNodeTopicsNotifier extends FamilyAsyncNotifier<List<Topic>, String> {
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<Topic>> build(String arg) async {
    _page = 1;
    _hasMore = true;
    return _fetchPage(1);
  }

  Future<List<Topic>> _fetchPage(int page) async {
    final api = V2exApiClient();
    final data = await api.getNodeTopics(arg, page: page);
    final topics = data.map((e) => Topic.fromJson(e as Map<String, dynamic>)).toList();
    if (topics.isEmpty || topics.length < 20) {
      _hasMore = false;
    }
    return topics;
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    // 触发 rebuild 以显示底部 loading
    state = AsyncValue.data(state.valueOrNull ?? []);

    try {
      _page++;
      final newTopics = await _fetchPage(_page);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([...current, ...newTopics]);
    } catch (e, stack) {
      _page--; // rollback
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }
}

final paginatedNodeTopicsProvider =
    AsyncNotifierProviderFamily<PaginatedNodeTopicsNotifier, List<Topic>, String>(
  PaginatedNodeTopicsNotifier.new,
);
