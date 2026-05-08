import 'package:chess/chess.dart' as ch;

class ChessService {
  static List<String> legalDestinations(String fen, String square) {
    final game = ch.Chess.fromFEN(fen);
    return game
        .generate_moves({'square': square})
        .map<String>((m) => m.toAlgebraic)
        .toList();
  }

  static String? applyMove(String fen, String san) {
    final game = ch.Chess.fromFEN(fen);
    if (!game.move(san)) return null;
    return game.fen;
  }

  static String? applyMoveFromTo(
    String fen,
    String from,
    String to, {
    String promotion = 'q',
  }) {
    final game = ch.Chess.fromFEN(fen);
    if (!game.move({'from': from, 'to': to, 'promotion': promotion})) return null;
    return game.fen;
  }

  static String? moveToSan(String fen, String from, String to) {
    final game = ch.Chess.fromFEN(fen);
    final moves = game.generate_moves({'square': from});
    for (final m in moves) {
      if (m.toAlgebraic == to) {
        return game.move_to_san(m);
      }
    }
    return null;
  }

  static Map<String, String>? pieceAt(String fen, String square) {
    final game = ch.Chess.fromFEN(fen);
    final piece = game.get(square);
    if (piece == null) return null;
    return {
      'type': piece.type.toLowerCase(),
      'color': piece.color == ch.Color.WHITE ? 'w' : 'b',
    };
  }

  static bool isLegalMove(String fen, String from, String to) {
    final game = ch.Chess.fromFEN(fen);
    final moves = game.generate_moves({'square': from});
    return moves.any((m) => m.toAlgebraic == to);
  }
}
