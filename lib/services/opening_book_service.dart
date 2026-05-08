import 'dart:convert';
import 'package:chess/chess.dart' as ch;
import 'package:flutter/services.dart';
import '../models/opening.dart';
import '../models/arrow.dart';

enum BookStatus { inBook, offBook, complete }

class BookResult {
  final BookStatus status;
  final List<Arrow> arrows;
  final String? variation;
  const BookResult({required this.status, required this.arrows, this.variation});
}

class _MatchResult {
  final List<MoveNode> children;
  final String? variation;
  const _MatchResult(this.children, this.variation);
}

class OpeningBookService {
  static const _assetPath = 'assets/openings/openings.json';

  List<Opening>? _openings;

  Future<List<Opening>> loadOpenings() async {
    if (_openings != null) return _openings!;
    final raw = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(raw) as List<dynamic>;
    _openings =
        list.map((e) => Opening.fromJson(e as Map<String, dynamic>)).toList();
    return _openings!;
  }

  BookResult getTopMoves(Opening opening, String fen) {
    final match = _findNodeForFen(opening.moves, fen);
    if (match == null) {
      return const BookResult(status: BookStatus.offBook, arrows: []);
    }
    if (match.children.isEmpty) {
      return BookResult(
          status: BookStatus.complete,
          arrows: [],
          variation: match.variation);
    }

    final sorted = [...match.children]
      ..sort((a, b) => b.weight.compareTo(a.weight));
    final top = sorted.take(3).toList();

    final arrows = <Arrow>[];
    for (int i = 0; i < top.length; i++) {
      final node = top[i];
      final squares = _sanToSquares(fen, node.san);
      if (squares == null) continue;
      arrows.add(Arrow(
        fromSquare: squares.$1,
        toSquare: squares.$2,
        rank: ArrowRank.values[i],
      ));
    }
    return BookResult(
        status: BookStatus.inBook,
        arrows: arrows,
        variation: match.variation);
  }

  _MatchResult? _findNodeForFen(List<MoveNode> roots, String targetFen) {
    return _searchTree(roots, ch.Chess(), targetFen, null);
  }

  _MatchResult? _searchTree(
    List<MoveNode> nodes,
    ch.Chess game,
    String targetFen,
    String? currentVariation,
  ) {
    if (_normalizeFen(game.fen) == _normalizeFen(targetFen)) {
      return _MatchResult(nodes, currentVariation);
    }
    for (final node in nodes) {
      final nextVariation = node.variation ?? currentVariation;
      final copy = ch.Chess.fromFEN(game.fen);
      if (!copy.move(node.san)) continue;
      final result =
          _searchTree(node.children, copy, targetFen, nextVariation);
      if (result != null) return result;
    }
    return null;
  }

  String _normalizeFen(String fen) {
    final parts = fen.split(' ');
    return parts.take(4).join(' ');
  }

  (String, String)? _sanToSquares(String fen, String san) {
    final game = ch.Chess.fromFEN(fen);
    final moves = game.generate_moves();
    for (final m in moves) {
      if (game.move_to_san(m) == san) {
        return (m.fromAlgebraic, m.toAlgebraic);
      }
    }
    return null;
  }
}
