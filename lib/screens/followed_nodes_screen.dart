import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/db_helper.dart';
import '../widgets/state_widgets.dart';

final followedNodesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return DbHelper.getFollowedNodes();
});

class FollowedNodesScreen extends ConsumerWidget {
  const FollowedNodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(followedNodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('已关注节点'),
        centerTitle: true,
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.star_border,
              message: '暂无关注的节点',
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(item['node_title'] ?? item['node_name']),
                subtitle: Text('/${item['node_name']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  tooltip: '取消关注',
                  onPressed: () async {
                    await DbHelper.unfollowNode(item['node_name'] as String);
                    ref.invalidate(followedNodesProvider);
                  },
                ),
                onTap: () => context.push('/node/${item['node_name']}'),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (err, _) => ErrorState(
          message: '加载失败: $err',
          onRetry: () => ref.invalidate(followedNodesProvider),
        ),
      ),
    );
  }
}
