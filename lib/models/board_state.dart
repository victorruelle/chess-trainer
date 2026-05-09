import 'package:flutter/foundation.dart';
import 'arrow.dart';
import 'opening_status.dart';

enum MoveQuality { correct, alternative, offBook }

@immutable
class MoveEval {
  final String playedSan;
  final String? bestSan; // gold book move before this move; null if already off-book
  final MoveQuality quality;

  const MoveEval({
    required this.playedSan,
    required this.bestSan,
    required this.quality,
  });
}

@immutable
class BoardState {
  final String fen;
  final List<String> moveHistory;
  final String? selectedSquare;
  final List<Arrow> arrows;
  final OpeningStatus status;
  final String? variation;
  final MoveEval? lastMoveEval;
  final int? movesRemaining;

  const BoardState({
    required this.fen,
    required this.moveHistory,
    this.selectedSquare,
    this.arrows = const [],
    required this.status,
    this.variation,
    this.lastMoveEval,
    this.movesRemaining,
  });

  static const initial = BoardState(
    fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    moveHistory: [],
    status: OpeningStatus.inBook,
  );

  BoardState copyWith({
    String? fen,
    List<String>? moveHistory,
    String? selectedSquare,
    bool clearSelection = false,
    List<Arrow>? arrows,
    OpeningStatus? status,
    String? variation,
    bool clearVariation = false,
    MoveEval? lastMoveEval,
    bool clearMoveEval = false,
    int? movesRemaining,
    bool clearMovesRemaining = false,
  }) {
    return BoardState(
      fen: fen ?? this.fen,
      moveHistory: moveHistory ?? this.moveHistory,
      selectedSquare: clearSelection ? null : (selectedSquare ?? this.selectedSquare),
      arrows: arrows ?? this.arrows,
      status: status ?? this.status,
      variation: clearVariation ? null : (variation ?? this.variation),
      lastMoveEval: clearMoveEval ? null : (lastMoveEval ?? this.lastMoveEval),
      movesRemaining: clearMovesRemaining ? null : (movesRemaining ?? this.movesRemaining),
    );
  }
}
