import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_toast.dart';
import '../utils/db_helper.dart';
import '../widgets/cached_avatar.dart';
import '../widgets/state_widgets.dart';

class FollowedMembersScreen extends ConsumerStatefulWidget {
  const FollowedMembersScreen({super.key});

  @override
  ConsumerState<FollowedMembersScreen> createState() =>
      _FollowedMembersScreenState();
}

class _FollowedMembersScreenState
    extends ConsumerState<FollowedMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final members = await DbHelper.getFollowedMembers();
    if (mounted) {
      setState(() {
        _members = members;
        _loading = false;
      });
    }
  }

  Future<void> _unfollow(String username) async {
    await DbHelper.unfollowMember(username);
    setState(() => _members.removeWhere((e) => e['username'] == username));
    if (mounted) AppToast.success(context, '已取消关注 $username');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('已关注成员'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const EmptyState(message: '还没有关注任何成员')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final entry = _members[index];
                    final username = entry['username'] as String;

                    return Dismissible(
                      key: ValueKey(username),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        color: cs.error,
                        child: Icon(Icons.person_remove, color: cs.onError),
                      ),
                      onDismissed: (_) => _unfollow(username),
                      child: ListTile(
                        leading: CachedAvatar(
                          fallbackText: username,
                          radius: 22,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: cs.outline,
                        ),
                        onTap: () => context.push('/member/$username'),
                      ),
                    );
                  },
                ),
    );
  }
}