import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_history_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/glass_search_bar.dart';
import '../widgets/state_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doSearch(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    ref.read(searchHistoryProvider.notifier).add(q);
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final history = ref.watch(searchHistoryProvider);
    final resultsAsync = _query.isNotEmpty ? ref.watch(searchProvider(_query)) : null;

    return Scaffold(
      appBar: AppBar(
        title: GlassSearchBar(
          controller: _controller,
          hintText: '搜索话题...',
          onSubmitted: _doSearch,
          onClear: () => setState(() => _query = ''),
        ),
        centerTitle: true,
      ),
      body: resultsAsync == null
          ? _buildSuggestions(history, cs)
          : resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return const EmptyState(message: '未找到相关话题');
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final r = results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 0,
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/topic/${r.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cs.tertiaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '话题',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onTertiaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      r.member,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${r.replies} 回复',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                r.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (r.content.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  r.content,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingState(),
              error: (err, _) => ErrorState(
                message: '搜索失败: $err',
                onRetry: () => ref.invalidate(searchProvider(_query)),
              ),
            ),
    );
  }

  Widget _buildSuggestions(List<String> history, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('搜索历史', style: Theme.of(context).textTheme.titleSmall),
              TextButton(
                onPressed: () => ref.read(searchHistoryProvider.notifier).clear(),
                child: const Text('清除'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.map((q) => ActionChip(
              label: Text(q),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                _controller.text = q;
                _doSearch(q);
              },
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text('热门搜索', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: defaultHotSearches.map((q) => InputChip(
            label: Text(q),
            visualDensity: VisualDensity.compact,
            selectedColor: cs.primaryContainer,
            onPressed: () {
              _controller.text = q;
              _doSearch(q);
            },
          )).toList(),
        ),
      ],
    );
  }
}
