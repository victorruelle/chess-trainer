import 'dart:async';

class EngineEval {
  final double score; // pawns, positive = White advantage
  final int depth;
  final String? bestMove; // UCI format e.g. "e2e4"

  const EngineEval({
    required this.score,
    required this.depth,
    this.bestMove,
  });

  bool get isMate => score.abs() > 100;

  String get display {
    if (isMate) {
      final m = ((200 - score.abs()) / 2).ceil();
      return score > 0 ? 'M$m' : '-M$m';
    }
    final sign = score > 0 ? '+' : '';
    return '$sign${score.toStringAsFixed(1)}';
  }
}

/// Singleton-pattern wrapper around the Stockfish UCI engine.
/// NOTE: Stockfish is not available in the web build. The app runs fine without it—
/// the eval bar shows as not ready. For full engine support, build for Android/iOS.
class StockfishService {
  dynamic _engine;
  StreamSubscription<String>? _sub;
  void Function(EngineEval)? _onUpdate;
  int _searchDepth = 0;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    // Engine not available without stockfish package
    _ready = false;
  }

  void evaluate(String fen, {required void Function(EngineEval) onUpdate, int depth = 20}) {
    // Engine not available without stockfish package
  }

  void stop() {
    // Engine not available without stockfish package
  }

  void dispose() {
    _sub?.cancel();
  }
}
