import '../services/stockfish_service.dart';

class ExplanationService {
  static OffBookExplanation explain({
    required EngineEval? prevEval,
    required EngineEval? currentEval,
    required String? bestMoveSan,
    required bool playerIsWhite,
  }) {
    if (currentEval == null) {
      return const OffBookExplanation(
        verdict: 'Analysing…',
        detail: 'Engine is evaluating the position.',
        severity: Severity.neutral,
      );
    }

    final delta = prevEval != null
        ? (currentEval.score - prevEval.score) * (playerIsWhite ? 1 : -1)
        : null;

    return OffBookExplanation(
      verdict: _verdict(currentEval.score, playerIsWhite),
      detail: _detail(delta: delta, currentEval: currentEval, bestMoveSan: bestMoveSan),
      severity: _severity(delta),
      bestMoveSan: bestMoveSan,
      evalDisplay: currentEval.display,
      depth: currentEval.depth,
    );
  }

  static String _verdict(double score, bool playerIsWhite) {
    final playerColor = playerIsWhite ? 'White' : 'Black';
    final opponentColor = playerIsWhite ? 'Black' : 'White';
    final playerScore = playerIsWhite ? score : -score;
    if (playerScore > 2.0) return '$playerColor has a clear advantage';
    if (playerScore > 0.5) return 'Slight edge to $playerColor';
    if (playerScore > -0.5) return 'Roughly equal position';
    if (playerScore > -1.5) return 'Slight edge to $opponentColor';
    if (playerScore > -3.0) return '$opponentColor has a clear advantage';
    return '$opponentColor is winning';
  }

  static String _detail({
    required double? delta,
    required EngineEval currentEval,
    required String? bestMoveSan,
  }) {
    final lines = <String>[];

    if (delta != null) {
      if (delta < -2.0) {
        lines.add('This move blundered — it cost roughly ${delta.abs().toStringAsFixed(1)} pawns.');
      } else if (delta < -1.0) {
        lines.add('A significant mistake, losing around ${delta.abs().toStringAsFixed(1)} pawns.');
      } else if (delta < -0.4) {
        lines.add('Somewhat imprecise — the engine prefers a different approach.');
      } else if (delta < 0) {
        lines.add('Marginally suboptimal, but a reasonable practical choice.');
      } else {
        lines.add('Technically sound, though it departs from the prepared line.');
      }
    }

    if (bestMoveSan != null) {
      lines.add('Engine recommendation: $bestMoveSan.');
    }

    lines.add(_positionCharacter(currentEval.score));
    return lines.join(' ');
  }

  static String _positionCharacter(double score) {
    final abs = score.abs();
    final winning = score > 0 ? 'White' : 'Black';
    final losing = score > 0 ? 'Black' : 'White';
    if (abs < 0.3) return 'The position is dynamically balanced.';
    if (abs < 0.8) return '$winning has a slight structural or activity edge.';
    if (abs < 1.8) return '$winning controls more space and has better piece coordination.';
    if (abs < 3.5) return '$winning has a decisive material or positional advantage.';
    return '$winning is winning. $losing needs to find precise defensive moves.';
  }

  static Severity _severity(double? delta) {
    if (delta == null) return Severity.neutral;
    if (delta < -2.0) return Severity.blunder;
    if (delta < -1.0) return Severity.mistake;
    if (delta < -0.3) return Severity.inaccuracy;
    return Severity.neutral;
  }
}

enum Severity { blunder, mistake, inaccuracy, neutral }

class OffBookExplanation {
  final String verdict;
  final String detail;
  final Severity severity;
  final String? bestMoveSan;
  final String? evalDisplay;
  final int? depth;

  const OffBookExplanation({
    required this.verdict,
    required this.detail,
    required this.severity,
    this.bestMoveSan,
    this.evalDisplay,
    this.depth,
  });
}
