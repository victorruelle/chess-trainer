/// Generates human-readable explanations for chess positions and moves
class ExplanationService {
  /// Generate explanation for why a move is off-book or suboptimal
  static String explainOffBookMove({
    required double beforeEval, // Eval before the move
    required double afterEval,  // Eval after the move
    required String bestMove,   // Engine's suggested best move
    required bool isWhiteToMove,
  }) {
    final evalDelta = afterEval - beforeEval;

    // If move significantly worsens position
    if (evalDelta < -1.5) {
      return 'This move loses significant material or position. Best move was $bestMove.';
    } else if (evalDelta < -0.8) {
      return 'This move weakens your position substantially. Consider $bestMove instead.';
    } else if (evalDelta < -0.3) {
      return 'Suboptimal choice. $bestMove was stronger.';
    } else if (evalDelta < 0) {
      return 'Slightly passive. Engine prefers $bestMove.';
    } else if (evalDelta < 0.3) {
      return 'Reasonable alternative to the main line ($bestMove).';
    } else {
      return 'Creative move! Deviates from the prepared variation.';
    }
  }

  /// Generate brief explanation for a position based on evaluation
  static String explainPosition(double eval, {bool isWhiteToMove = true}) {
    final absEval = eval.abs();

    if (eval > 3) {
      return isWhiteToMove
        ? 'White has a dominant advantage.'
        : 'Black has a dominant advantage.';
    } else if (eval > 1.5) {
      return isWhiteToMove
        ? 'White is significantly better.'
        : 'Black is significantly better.';
    } else if (eval > 0.5) {
      return isWhiteToMove
        ? 'White has a moderate advantage.'
        : 'Black has a moderate advantage.';
    } else if (eval > -0.5 && eval < 0.5) {
      return 'Position is roughly equal.';
    } else if (eval < -0.5) {
      return isWhiteToMove
        ? 'Black has an advantage.'
        : 'White has an advantage.';
    } else {
      return 'Balanced position.';
    }
  }

  /// Human-friendly display of centipawn scores
  static String formatScore(double pawnScore) {
    if (pawnScore.abs() > 10) {
      // Likely mate
      final mateIn = ((20 - pawnScore.abs()) / 2).ceil();
      return pawnScore > 0 ? 'M+$mateIn' : 'M-$mateIn';
    }
    return pawnScore.toStringAsFixed(1);
  }
}
