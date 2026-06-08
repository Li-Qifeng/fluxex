import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/node_provider.dart';

class NodesScreen extends ConsumerStatefulWidget {
  const NodesScreen({super.key});

  @override
  ConsumerState<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends ConsumerState<NodesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(allNodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('节点'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: '搜索节点...',
              leading: const Icon(Icons.search),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: nodesAsync.when(
        data: (nodes) {
          final filtered = _searchQuery.isEmpty
              ? nodes
              : nodes.where((n) =>
                  n.title.toLowerCase().contains(_searchQuery) ||
                  n.name.toLowerCase().contains(_searchQuery) ||
                  n.titleAlternative.toLowerCase().contains(_searchQuery)).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('未找到匹配的节点'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final node = filtered[index];
              return ListTile(
                leading: node.avatarNormal.isNotEmpty
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(node.avatarNormal),
                        backgroundColor: Colors.transparent,
                      )
                    : CircleAvatar(
                        radius: 18,
                        child: Text(node.title[0]),
                      ),
                title: Text(node.title),
                subtitle: Text(
                  node.titleAlternative,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: node.topics != null
                    ? Text(
                        '${node.topics} 话题',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      )
                    : null,
                onTap: () => context.push('/node/${node.name}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(allNodesProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
