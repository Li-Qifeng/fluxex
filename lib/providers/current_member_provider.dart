import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import 'auth_provider.dart';

final currentMemberProvider = FutureProvider<Member?>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isLoggedIn || auth.username == null) return null;
  try {
    final service = MemberService();
    final data = await service.getInfo(auth.username!);
    return Member.fromJson(data);
  } catch (_) {
    return null;
  }
});
