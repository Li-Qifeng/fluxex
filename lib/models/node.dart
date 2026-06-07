class Node {
  final int id;
  final String name;
  final String title;
  final String titleAlternative;
  final String url;
  final String? header;
  final String? footer;
  final int? topics;
  final int? stars;
  final String avatarMini;
  final String avatarNormal;
  final String avatarLarge;

  Node({
    required this.id,
    required this.name,
    required this.title,
    required this.titleAlternative,
    required this.url,
    this.header,
    this.footer,
    this.topics,
    this.stars,
    required this.avatarMini,
    required this.avatarNormal,
    required this.avatarLarge,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'] as int,
      name: json['name'] as String,
      title: json['title'] as String,
      titleAlternative: json['title_alternative'] as String,
      url: json['url'] as String,
      header: json['header'] as String?,
      footer: json['footer'] as String?,
      topics: json['topics'] as int?,
      stars: json['stars'] as int?,
      avatarMini: json['avatar_mini'] as String,
      avatarNormal: json['avatar_normal'] as String,
      avatarLarge: json['avatar_large'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'title_alternative': titleAlternative,
    'url': url,
    'header': header,
    'footer': footer,
    'topics': topics,
    'stars': stars,
    'avatar_mini': avatarMini,
    'avatar_normal': avatarNormal,
    'avatar_large': avatarLarge,
  };
}
