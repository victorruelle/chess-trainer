import 'package:flutter/foundation.dart';

@immutable
class MoveNode {
  final String san;
  final int weight;
  final String? explanation;
  final String? variation;
  final List<MoveNode> children;

  const MoveNode({
    required this.san,
    required this.weight,
    this.explanation,
    this.variation,
    this.children = const [],
  });

  factory MoveNode.fromJson(Map<String, dynamic> json) => MoveNode(
        san: json['san'] as String,
        weight: json['weight'] as int,
        explanation: json['explanation'] as String?,
        variation: json['variation'] as String?,
        children: (json['children'] as List<dynamic>? ?? [])
            .map((e) => MoveNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class Opening {
  final String id;
  final String name;
  final String eco;
  final String color;
  final List<MoveNode> moves;

  const Opening({
    required this.id,
    required this.name,
    required this.eco,
    required this.color,
    required this.moves,
  });

  factory Opening.fromJson(Map<String, dynamic> json) => Opening(
        id: json['id'] as String,
        name: json['name'] as String,
        eco: json['eco'] as String,
        color: json['color'] as String,
        moves: (json['moves'] as List<dynamic>)
            .map((e) => MoveNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
