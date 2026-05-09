import 'dart:async';

// dart.library.html is only defined on web — on native, stockfish_native.dart
// is chosen (dart:ffi). On web, stockfish_stub.dart runs Stockfish.js via Worker.
import 'stockfish_native.dart' if (dart.library.html) 'stockfish_stub.dart';

class EngineEval {
  final double score; // pawns, White POV
  final int depth;
  final String? bestMove; // UCI e.g. "e2e4"

  const EngineEval({required this.score, required this.depth, this.bestMove});

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

class StockfishService {
  Stockfish? _engine;
  StreamSubscription<String>? _sub;
  void Function(EngineEval)? _onUpdate;
  void Function(List<String>)? _onTopMoves;
  final Map<int, String> _pvMoves = {}; // multipv index → UCI move
  int _searchDepth = 0;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    try {
      _engine = Stockfish();
      final completer = Completer<void>();

      // Subscribe before sending any commands to avoid missing readyok
      _sub = _engine!.stdout.listen((line) {
        if (!completer.isCompleted && line.contains('readyok')) {
          completer.complete();
        }
        _onLine(line);
      });

      // Standard UCI handshake — works for both native Stockfish and Stockfish.js
      _engine!.stdin = 'uci';
      _engine!.stdin = 'isready';

      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {},
      );

      // Enable MultiPV so we get top 3 candidate moves
      _engine!.stdin = 'setoption name MultiPV value 3';
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  void evaluate(
    String fen, {
    required void Function(EngineEval) onUpdate,
    void Function(List<String>)? onTopMoves,
    int depth = 20,
  }) {
    if (!_ready || _engine == null) return;
    _onUpdate = onUpdate;
    _onTopMoves = onTopMoves;
    _searchDepth = 0;
    _pvMoves.clear();
    _engine!.stdin = 'stop';
    _engine!.stdin = 'position fen $fen';
    _engine!.stdin = 'go depth $depth';
  }

  void stop() {
    if (_engine != null) _engine!.stdin = 'stop';
    _onUpdate = null;
    _onTopMoves = null;
  }

  void _onLine(String line) {
    if (!line.startsWith('info')) return;
    _parseLine(line);
  }

  void _parseLine(String line) {
    final parts = line.split(' ');
    var depth = 0;
    var scoreCP = 0;
    var multipv = 1;
    String? bestMove;

    for (int i = 0; i < parts.length; i++) {
      switch (parts[i]) {
        case 'depth':
          if (i + 1 < parts.length) depth = int.tryParse(parts[i + 1]) ?? 0;
        case 'multipv':
          if (i + 1 < parts.length) multipv = int.tryParse(parts[i + 1]) ?? 1;
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

    if (depth == 0) return;

    if (bestMove != null) {
      _pvMoves[multipv] = bestMove;
      // Report updated top-moves list after every pv line
      final tops = [
        if (_pvMoves.containsKey(1)) _pvMoves[1]!,
        if (_pvMoves.containsKey(2)) _pvMoves[2]!,
        if (_pvMoves.containsKey(3)) _pvMoves[3]!,
      ];
      _onTopMoves?.call(tops);
    }

    // Only update main eval from the best line (multipv 1)
    if (multipv == 1 && depth >= _searchDepth) {
      _searchDepth = depth;
      _onUpdate?.call(
        EngineEval(score: scoreCP / 100.0, depth: depth, bestMove: bestMove),
      );
    }
  }

  void dispose() {
    if (_engine != null) _engine!.stdin = 'quit';
    _sub?.cancel();
    _engine = null;
    _ready = false;
  }
}
