import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/db_helper.dart';
import '../models/topic.dart';

final bookmarksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DbHelper.getBookmarks();
});

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书签'),
        centerTitle: true,
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('暂无书签'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['title'] ?? '无标题'),
                subtitle: item['note'] != null && (item['note'] as String).isNotEmpty
                    ? Text(item['note'] as String)
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await DbHelper.removeBookmark(item['topic_id'] as int);
                    ref.invalidate(bookmarksProvider);
                  },
                ),
                onTap: () => context.push('/topic/${item['topic_id']}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
      ),
    );
  }
}
