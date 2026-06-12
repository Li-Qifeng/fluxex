class Member {
  final int id;
  final String username;
  final String url;
  final String? website;
  final String? twitter;
  final String? github;
  final String? psn;
  final String? btc;
  final String? location;
  final String? tagline;
  final String? bio;
  final String avatarMini;
  final String avatarNormal;
  final String avatarLarge;
  final int created;
  final int lastModified;
  final int? pro;

  Member({
    required this.id,
    required this.username,
    required this.url,
    this.website,
    this.twitter,
    this.github,
    this.psn,
    this.btc,
    this.location,
    this.tagline,
    this.bio,
    required this.avatarMini,
    required this.avatarNormal,
    required this.avatarLarge,
    required this.created,
    required this.lastModified,
    this.pro,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      username: json['username'] as String,
      url: json['url'] as String,
      website: json['website'] as String?,
      twitter: json['twitter'] as String?,
      github: json['github'] as String?,
      psn: json['psn'] as String?,
      btc: json['btc'] as String?,
      location: json['location'] as String?,
      tagline: json['tagline'] as String?,
      bio: json['bio'] as String?,
      avatarMini: json['avatar_mini'] as String,
      avatarNormal: json['avatar_normal'] as String,
      avatarLarge: json['avatar_large'] as String,
      created: json['created'] as int,
      lastModified: json['last_modified'] as int,
      pro: json['pro'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'url': url,
    'website': website,
    'twitter': twitter,
    'github': github,
    'psn': psn,
    'btc': btc,
    'location': location,
    'tagline': tagline,
    'bio': bio,
    'avatar_mini': avatarMini,
    'avatar_normal': avatarNormal,
    'avatar_large': avatarLarge,
    'created': created,
    'last_modified': lastModified,
    'pro': pro,
  };
}
