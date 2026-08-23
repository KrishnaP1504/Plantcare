/// Represents a user in the Plantcare app.
class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final int level;
  final int xp;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.level = 1,
    this.xp = 0,
    this.avatarUrl,
  });

  /// XP required for the current level.
  int get xpForCurrentLevel => level * 100;

  /// Progress toward the next level (0.0 to 1.0).
  double get levelProgress => xp / xpForCurrentLevel;

  /// Display title based on level.
  String get levelTitle {
    if (level <= 2) return 'Novice';
    if (level <= 5) return 'Gardener';
    if (level <= 10) return 'Botanist';
    if (level <= 20) return 'Plant Expert';
    return 'Master Botanist';
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    int? level,
    int? xp,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'level': level,
      'xp': xp,
      'avatar_url': avatarUrl,
    };
  }
}
