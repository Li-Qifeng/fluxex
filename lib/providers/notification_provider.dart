import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class UnreadCountNotifier extends StateNotifier<int> {
  UnreadCountNotifier() : super(0) {
    _startPolling();
  }

  Timer? _timer;

  void _startPolling() {
    _fetch();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final count = await V2exApiClient().fetchUnreadNotificationCount();
      state = count;
    } catch (_) {
      state = 0;
    }
  }

  void refresh() => _fetch();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  return UnreadCountNotifier();
});
