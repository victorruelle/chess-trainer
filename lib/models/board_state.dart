import 'package:flutter/foundation.dart';
import 'arrow.dart';
import 'opening_status.dart';

@immutable
class BoardState {
  final String fen;
  final List<String> moveHistory;
  final String? selectedSquare;
  final List<Arrow> arrows;
  final OpeningStatus status;

  const BoardState({
    required this.fen,
    required this.moveHistory,
    this.selectedSquare,
    this.arrows = const [],
    required this.status,
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
  }) {
    return BoardState(
      fen: fen ?? this.fen,
      moveHistory: moveHistory ?? this.moveHistory,
      selectedSquare: clearSelection ? null : (selectedSquare ?? this.selectedSquare),
      arrows: arrows ?? this.arrows,
      status: status ?? this.status,
    );
  }
}
