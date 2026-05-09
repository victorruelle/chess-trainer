import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_state.dart';
import '../models/opening_status.dart';
import '../models/arrow.dart';
import '../services/chess_service.dart';
import '../services/opening_book_service.dart';
import 'opening_provider.dart';

class BoardNotifier extends Notifier<BoardState> {
  @override
  BoardState build() => BoardState.initial;

  void initForOpening() {
    final opening = ref.read(selectedOpeningProvider);
    if (opening == null) return;
    final result = _bookResult(BoardState.initial.fen);
    state = BoardState.initial.copyWith(
      arrows: result.arrows,
      status: _toStatus(result.status),
      variation: result.variation,
      movesRemaining: result.movesRemaining,
      clearMovesRemaining: result.movesRemaining == null,
    );
  }

  void onSquareTapped(String square) {
    final current = state;

    if (current.selectedSquare != null) {
      if (ChessService.isLegalMove(current.fen, current.selectedSquare!, square)) {
        _applyMoveFromTo(current.selectedSquare!, square);
        return;
      }
    }

    final piece = ChessService.pieceAt(current.fen, square);
    if (piece != null) {
      state = current.copyWith(selectedSquare: square);
      return;
    }

    state = current.copyWith(clearSelection: true);
  }

  void _applyMoveFromTo(String from, String to) {
    final san = ChessService.moveToSan(state.fen, from, to);
    if (san == null) return;

    // Capture move quality before the position changes
    final moveEval = _evalMove(san, state.arrows, state.status);

    final newFen = ChessService.applyMoveFromTo(state.fen, from, to);
    if (newFen == null) return;

    final result = _bookResult(newFen);
    state = state.copyWith(
      fen: newFen,
      moveHistory: [...state.moveHistory, san],
      clearSelection: true,
      arrows: result.arrows,
      status: _toStatus(result.status),
      variation: result.variation,
      lastMoveEval: moveEval,
      movesRemaining: result.movesRemaining,
      clearMovesRemaining: result.movesRemaining == null,
    );
  }

  MoveEval _evalMove(String san, List<Arrow> arrows, OpeningStatus status) {
    if (arrows.isEmpty || status != OpeningStatus.inBook) {
      return MoveEval(playedSan: san, bestSan: null, quality: MoveQuality.offBook);
    }
    final bestSan = arrows.first.san; // gold arrow
    if (san == bestSan) {
      return MoveEval(playedSan: san, bestSan: bestSan, quality: MoveQuality.correct);
    }
    if (arrows.any((a) => a.san == san)) {
      return MoveEval(playedSan: san, bestSan: bestSan, quality: MoveQuality.alternative);
    }
    return MoveEval(playedSan: san, bestSan: bestSan, quality: MoveQuality.offBook);
  }

  void undo() {
    if (state.moveHistory.isEmpty) return;

    final history = state.moveHistory.sublist(0, state.moveHistory.length - 1);
    var fen = BoardState.initial.fen;
    for (final san in history) {
      fen = ChessService.applyMove(fen, san) ?? fen;
    }

    final result = _bookResult(fen);
    state = state.copyWith(
      fen: fen,
      moveHistory: history,
      clearSelection: true,
      arrows: result.arrows,
      status: _toStatus(result.status),
      variation: result.variation,
      clearMoveEval: true,
      movesRemaining: result.movesRemaining,
      clearMovesRemaining: result.movesRemaining == null,
    );
  }

  void reset() {
    initForOpening();
  }

  BookResult _bookResult(String fen) {
    final opening = ref.read(selectedOpeningProvider);
    if (opening == null) {
      return const BookResult(status: BookStatus.offBook, arrows: []);
    }
    final service = ref.read(openingBookServiceProvider);
    return service.getTopMoves(opening, fen);
  }

  OpeningStatus _toStatus(BookStatus status) => switch (status) {
        BookStatus.inBook => OpeningStatus.inBook,
        BookStatus.offBook => OpeningStatus.offBook,
        BookStatus.complete => OpeningStatus.complete,
      };
}

final boardProvider =
    NotifierProvider<BoardNotifier, BoardState>(BoardNotifier.new);

// Formatted move list for display in the bottom sheet
final moveListProvider = Provider<String>((ref) {
  final history = ref.watch(boardProvider).moveHistory;
  if (history.isEmpty) return '';
  final buffer = StringBuffer();
  for (int i = 0; i < history.length; i++) {
    if (i % 2 == 0) buffer.write('${(i ~/ 2) + 1}. ');
    buffer.write(history[i]);
    if (i % 2 == 0 && i + 1 < history.length) {
      buffer.write(' ');
    } else if (i % 2 == 1) {
      buffer.write('  ');
    }
  }
  return buffer.toString().trim();
});
