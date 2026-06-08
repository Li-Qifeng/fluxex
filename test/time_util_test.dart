import 'package:flutter_test/flutter_test.dart';
import 'package:fluxex/utils/time_util.dart';

void main() {
  group('formatRelativeTime', () {
    test('returns seconds ago for recent timestamps', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect(formatRelativeTime(now - 30), '30秒前');
    });

    test('returns minutes ago', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect(formatRelativeTime(now - 120), '2分钟前');
    });

    test('returns hours ago', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect(formatRelativeTime(now - 7200), '2小时前');
    });

    test('returns days ago', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      expect(formatRelativeTime(now - 86400 * 3), '3天前');
    });
  });

  group('formatAbsoluteTime', () {
    test('formats as MM-DD HH:mm for this year', () {
      final now = DateTime.now();
      final ts = DateTime(now.year, 6, 15, 14, 30).millisecondsSinceEpoch ~/ 1000;
      expect(formatAbsoluteTime(ts), '06-15 14:30');
    });

    test('formats as YYYY-MM-DD HH:mm for past years', () {
      final ts = DateTime(2023, 1, 1, 0, 0).millisecondsSinceEpoch ~/ 1000;
      expect(formatAbsoluteTime(ts), '2023-01-01 00:00');
    });
  });
}
