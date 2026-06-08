import 'package:flutter_test/flutter_test.dart';
import 'package:fluxex/models/topic.dart';
import 'package:fluxex/models/member.dart';
import 'package:fluxex/models/node.dart';

void main() {
  group('Topic.fromJson', () {
    test('parses basic topic', () {
      final topic = Topic.fromJson({
        'id': 123,
        'title': 'Hello World',
        'url': 'https://v2ex.com/t/123',
        'content': 'Test content',
        'content_rendered': '<p>Test</p>',
        'replies': 5,
        'member': {
          'id': 1,
          'username': 'test',
          'url': 'https://v2ex.com/member/test',
          'avatar_mini': 'a.jpg',
          'avatar_normal': 'b.jpg',
          'avatar_large': 'c.jpg',
          'created': 0,
          'last_modified': 0,
        },
        'node': {
          'id': 1,
          'name': 'test',
          'title': 'Test Node',
          'title_alternative': 'Test',
          'url': 'https://v2ex.com/go/test',
          'avatar_mini': 'a.jpg',
          'avatar_normal': 'b.jpg',
          'avatar_large': 'c.jpg',
        },
        'created': 1609459200,
        'last_modified': 1609459200,
        'last_touched': 1609459200,
      });
      expect(topic.id, 123);
      expect(topic.title, 'Hello World');
      expect(topic.replies, 5);
    });
  });

  group('Member.fromJson', () {
    test('parses member with optional fields', () {
      final member = Member.fromJson({
        'id': 1,
        'username': 'testuser',
        'url': 'https://v2ex.com/member/testuser',
        'avatar_mini': 'a.jpg',
        'avatar_normal': 'b.jpg',
        'avatar_large': 'c.jpg',
        'created': 1609459200,
        'last_modified': 1609459200,
        'website': 'https://example.com',
        'github': 'testuser',
      });
      expect(member.username, 'testuser');
      expect(member.website, 'https://example.com');
      expect(member.github, 'testuser');
    });
  });

  group('Node.fromJson', () {
    test('parses node correctly', () {
      final node = Node.fromJson({
        'id': 1,
        'name': 'programmer',
        'title': '程序员',
        'title_alternative': 'Programmer',
        'url': 'https://v2ex.com/go/programmer',
        'avatar_mini': 'a.jpg',
        'avatar_normal': 'b.jpg',
        'avatar_large': 'c.jpg',
        'topics': 1000,
        'stars': 500,
      });
      expect(node.name, 'programmer');
      expect(node.title, '程序员');
      expect(node.topics, 1000);
    });
  });
}
