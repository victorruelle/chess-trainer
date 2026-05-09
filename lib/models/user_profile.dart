import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String name;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  static final victor = UserProfile(
    id: 'victor',
    name: 'Victor',
    createdAt: DateTime(2024),
  );

  static final alexi = UserProfile(
    id: 'alexi',
    name: 'Alexis',
    createdAt: DateTime(2024),
  );

  static List<UserProfile> get all => [victor, alexi];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
      );
}
