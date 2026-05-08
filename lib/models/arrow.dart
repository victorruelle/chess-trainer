import 'package:flutter/material.dart';

enum ArrowRank { gold, silver, bronze }

@immutable
class Arrow {
  final String fromSquare;
  final String toSquare;
  final ArrowRank rank;

  const Arrow({
    required this.fromSquare,
    required this.toSquare,
    required this.rank,
  });
}

extension ArrowRankStyle on ArrowRank {
  Color get color => switch (this) {
        ArrowRank.gold => const Color(0xFFFFD700),
        ArrowRank.silver => const Color(0xFFC0C0C0),
        ArrowRank.bronze => const Color(0xFFCD7F32),
      };

  double get opacity => switch (this) {
        ArrowRank.gold => 0.85,
        ArrowRank.silver => 0.75,
        ArrowRank.bronze => 0.65,
      };
}
