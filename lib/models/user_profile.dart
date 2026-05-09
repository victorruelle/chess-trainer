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
