import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxex/app.dart';
import 'package:fluxex/models/topic_list_result.dart';
import 'package:fluxex/providers/notification_provider.dart';
import 'package:fluxex/providers/topic_list_provider.dart';

void main() {
  test('FluxEx app can be constructed', () {
    expect(const V2exApp(), isA<V2exApp>());
  });

  testWidgets('FluxEx app boots inside ProviderScope', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadCountProvider.overrideWith((ref) => _FakeUnreadCountNotifier()),
          hotTopicsProvider.overrideWith((ref) async => TopicListResult([])),
          latestTopicsProvider.overrideWith((ref) async => TopicListResult([])),
        ],
        child: const V2exApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('V2EX'), findsOneWidget);
  });

  testWidgets('Home shows error state instead of blank when initial topic load fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadCountProvider.overrideWith((ref) => _FakeUnreadCountNotifier()),
          hotTopicsProvider.overrideWith(
            (ref) async => TopicListResult([], error: Exception('network failed')),
          ),
          latestTopicsProvider.overrideWith((ref) async => TopicListResult([])),
        ],
        child: const V2exApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}

class _FakeUnreadCountNotifier extends UnreadCountNotifier {
  _FakeUnreadCountNotifier() : super(enablePolling: false);

  @override
  void refresh() {}
}
