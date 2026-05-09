import 'package:flutter/foundation.dart';

@immutable
class TrainingSession {
  final String id;
  final String profileId;
  final String openingId;
  final String openingName;
  final String? variation;
  final int correctMoves;
  final int totalMoves;
  final bool completed;
  final DateTime startedAt;

  const TrainingSession({
    required this.id,
    required this.profileId,
    required this.openingId,
    required this.openingName,
    this.variation,
    required this.correctMoves,
    required this.totalMoves,
    required this.completed,
    required this.startedAt,
  });

  double get accuracy => totalMoves == 0 ? 0 : correctMoves / totalMoves;

  Map<String, dynamic> toMap() => {
        'id': id,
        'profileId': profileId,
        'openingId': openingId,
        'openingName': openingName,
        'variation': variation,
        'correctMoves': correctMoves,
        'totalMoves': totalMoves,
        'completed': completed ? 1 : 0,
        'startedAt': startedAt.millisecondsSinceEpoch,
      };

  factory TrainingSession.fromMap(Map<String, dynamic> m) => TrainingSession(
        id: m['id'] as String,
        profileId: m['profileId'] as String,
        openingId: m['openingId'] as String,
        openingName: m['openingName'] as String,
        variation: m['variation'] as String?,
        correctMoves: m['correctMoves'] as int,
        totalMoves: m['totalMoves'] as int,
        completed: (m['completed'] as int) == 1,
        startedAt:
            DateTime.fromMillisecondsSinceEpoch(m['startedAt'] as int),
      );
}
