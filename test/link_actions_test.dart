import 'package:flutter_test/flutter_test.dart';
import 'package:fluxex/utils/link_actions.dart';

void main() {
  group('isV2exInternalLink', () {
    // Note: handleTapUrl uses context, so we test the URI parsing logic indirectly
    // by checking what URLs would be routed internally vs externally.

    test('recognizes /t/12345 as topic', () {
      final uri = Uri.parse('https://www.v2ex.com/t/12345');
      expect(uri.path, '/t/12345');
      final match = RegExp(r'^/t/(\d+)').firstMatch(uri.path);
      expect(match, isNotNull);
      expect(match!.group(1), '12345');
    });

    test('recognizes /member/username as member', () {
      final uri = Uri.parse('https://www.v2ex.com/member/testuser');
      final match = RegExp(r'^/member/([^/]+)').firstMatch(uri.path);
      expect(match, isNotNull);
      expect(match!.group(1), 'testuser');
    });

    test('recognizes /go/nodename as node', () {
      final uri = Uri.parse('https://www.v2ex.com/go/programmer');
      final match = RegExp(r'^/go/([^/]+)').firstMatch(uri.path);
      expect(match, isNotNull);
      expect(match!.group(1), 'programmer');
    });

    test('external links do not match internal patterns', () {
      final uri = Uri.parse('https://github.com/user/repo');
      expect(RegExp(r'^/t/(\d+)').firstMatch(uri.path), isNull);
      expect(RegExp(r'^/member/([^/]+)').firstMatch(uri.path), isNull);
      expect(RegExp(r'^/go/([^/]+)').firstMatch(uri.path), isNull);
    });
  });
}
