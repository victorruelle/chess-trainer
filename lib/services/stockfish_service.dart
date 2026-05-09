import 'dart:async';

// dart.library.html is only defined on web — on native, stockfish_native.dart
// is chosen, which re-exports the real Stockfish (using dart:ffi).
// On web, stockfish_stub.dart is chosen, which runs Stockfish.js in a Web Worker.
import 'stockfish_native.dart' if (dart.library.html) 'stockfish_stub.dart';

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

/// Wrapper around the Stockfish UCI engine.
/// On web the stub is used and isReady stays false — the app works without engine.
class StockfishService {
  Stockfish? _engine;
  StreamSubscription<String>? _sub;
  void Function(EngineEval)? _onUpdate;
  int _searchDepth = 0;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    try {
      _engine = Stockfish();
      await _engine!.stdout
          .firstWhere((l) => l.contains('readyok'))
          .timeout(const Duration(seconds: 8), onTimeout: () => '');
      _sub = _engine!.stdout.listen(_onLine);
      _ready = true;
    } catch (e) {
      _ready = false;
    }
  }

  void _onLine(String line) {
    if (!line.startsWith('info')) return;
    final eval = _parseLine(line);
    if (eval == null) return;
    if (eval.depth >= _searchDepth) {
      _searchDepth = eval.depth;
      _onUpdate?.call(eval);
    }
  }

  void evaluate(String fen, {required void Function(EngineEval) onUpdate, int depth = 20}) {
    if (!_ready || _engine == null) return;
    _onUpdate = onUpdate;
    _searchDepth = 0;
    _engine!.stdin = 'stop';
    _engine!.stdin = 'position fen $fen';
    _engine!.stdin = 'go depth $depth';
  }

  void stop() {
    if (_engine != null) _engine!.stdin = 'stop';
    _onUpdate = null;
  }

  EngineEval? _parseLine(String line) {
    final parts = line.split(' ');
    var depth = 0;
    var scoreCP = 0;
    String? bestMove;

    for (int i = 0; i < parts.length; i++) {
      switch (parts[i]) {
        case 'depth':
          if (i + 1 < parts.length) depth = int.tryParse(parts[i + 1]) ?? 0;
        case 'score':
          if (i + 2 < parts.length) {
            if (parts[i + 1] == 'cp') {
              scoreCP = int.tryParse(parts[i + 2]) ?? 0;
            } else if (parts[i + 1] == 'mate') {
              final m = int.tryParse(parts[i + 2]) ?? 0;
              scoreCP = m > 0 ? (200 - m) * 100 : (-200 - m) * 100;
            }
          }
        case 'pv':
          if (i + 1 < parts.length) bestMove = parts[i + 1];
      }
    }

    if (depth == 0) return null;
    return EngineEval(score: scoreCP / 100.0, depth: depth, bestMove: bestMove);
  }

  void dispose() {
    if (_engine != null) _engine!.stdin = 'quit';
    _sub?.cancel();
    _engine = null;
    _ready = false;
  }
}
