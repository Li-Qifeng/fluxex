import 'member.dart';
import 'node.dart';

class Topic {
  final int id;
  final String title;
  final String url;
  final String? content;
  final String? contentRendered;
  final int replies;
  final Member member;
  final Node node;
  final int created;
  final int lastModified;
  final int lastTouched;
  final String? lastReplyBy;

  Topic({
    required this.id,
    required this.title,
    required this.url,
    this.content,
    this.contentRendered,
    required this.replies,
    required this.member,
    required this.node,
    required this.created,
    required this.lastModified,
    required this.lastTouched,
    this.lastReplyBy,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      content: json['content'] as String?,
      contentRendered: json['content_rendered'] as String?,
      replies: json['replies'] as int,
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      node: Node.fromJson(json['node'] as Map<String, dynamic>),
      created: json['created'] as int,
      lastModified: json['last_modified'] as int,
      lastTouched: json['last_touched'] as int,
      lastReplyBy: json['last_reply_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'content': content,
    'content_rendered': contentRendered,
    'replies': replies,
    'member': member.toJson(),
    'node': node.toJson(),
    'created': created,
    'last_modified': lastModified,
    'last_touched': lastTouched,
    'last_reply_by': lastReplyBy,
  };
}
