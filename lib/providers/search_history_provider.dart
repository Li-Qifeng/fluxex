import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _searchHistoryKey = 'search_history';
const defaultHotSearches = ['AI', 'Flutter', 'macOS', 'iOS', '远程工作', '创业', '程序员', 'NAS'];

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_searchHistoryKey) ?? const [];
  }

  Future<void> add(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;
    final next = [value, ...state.where((e) => e != value)].take(10).toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_searchHistoryKey, next);
  }

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(),
);
