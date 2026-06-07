import 'member.dart';

class Reply {
  final int id;
  final int topicId;
  final int memberId;
  final String? content;
  final String? contentRendered;
  final Member member;
  final int created;
  final int lastModified;

  Reply({
    required this.id,
    required this.topicId,
    required this.memberId,
    this.content,
    this.contentRendered,
    required this.member,
    required this.created,
    required this.lastModified,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'] as int,
      topicId: json['topic_id'] as int,
      memberId: json['member_id'] as int,
      content: json['content'] as String?,
      contentRendered: json['content_rendered'] as String?,
      member: Member.fromJson(json['member'] as Map<String, dynamic>),
      created: json['created'] as int,
      lastModified: json['last_modified'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic_id': topicId,
    'member_id': memberId,
    'content': content,
    'content_rendered': contentRendered,
    'member': member.toJson(),
    'created': created,
    'last_modified': lastModified,
  };
}
