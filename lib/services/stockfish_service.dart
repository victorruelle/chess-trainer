import 'package:stockfish/stockfish.dart';

class EngineEval {
  final double score; // in pawns, positive = White advantage
  final int depth;
  final String? bestMove;
  final List<String> pv; // principal variation

  const EngineEval({
    required this.score,
    required this.depth,
    this.bestMove,
    this.pv = const [],
  });

  bool get isMate => score.abs() > 10; // Mate detected (>10 pawns)

  @override
  String toString() {
    if (isMate) {
      final mateIn = ((20 - score.abs()) / 2).ceil();
      return score > 0 ? 'M$mateIn' : '-M$mateIn';
    }
    return score.toStringAsFixed(1);
  }
}

class StockfishService {
  static Stockfish? _instance;
  late Stream<String> _output;
  EngineEval? _lastEval;

  Future<void> init() async {
    try {
      _instance = Stockfish();
      _output = _instance!.stdout;
      await Future.delayed(const Duration(milliseconds: 500));
      await _isReady();
    } catch (e) {
      print('Stockfish init error: $e');
    }
  }

  Future<void> _isReady() async {
    if (_instance == null) return;
    _instance!.stdin = 'isready';
    // Wait for readyok response
    await _output.firstWhere((line) => line.contains('readyok')).timeout(
      const Duration(seconds: 5),
      onTimeout: () => 'readyok',
    );
  }

  Future<EngineEval?> evaluatePosition(String fen, {int depth = 18}) async {
    if (_instance == null) return null;

    final completer = <EngineEval?>{};
    var bestDepth = 0;
    EngineEval? bestEval;

    final subscription = _output.listen((line) {
      if (line.startsWith('info')) {
        final eval = _parseInfo(line);
        if (eval.depth >= bestDepth) {
          bestDepth = eval.depth;
          bestEval = eval;
        }
      }
    });

    try {
      _instance!.stdin = 'position fen $fen';
      _instance!.stdin = 'go depth $depth';

      // Wait for bestmove line (signals search completion)
      await _output
          .firstWhere((line) => line.startsWith('bestmove'))
          .timeout(const Duration(seconds: 30));

      _lastEval = bestEval;
      return bestEval;
    } finally {
      subscription.cancel();
    }
  }

  EngineEval _parseInfo(String line) {
    // Example: info depth 20 seldepth 25 multipv 1 score cp 52 nodes 1234567 nps 617284 tbhits 0 time 2000 pv e2e4 c7c5
    final parts = line.split(' ');
    var depth = 0;
    var scoreCP = 0;
    var bestMove = '';
    final pv = <String>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == 'depth' && i + 1 < parts.length) {
        depth = int.tryParse(parts[i + 1]) ?? 0;
      } else if (parts[i] == 'score') {
        if (i + 2 < parts.length) {
          if (parts[i + 1] == 'cp') {
            scoreCP = int.tryParse(parts[i + 2]) ?? 0;
          } else if (parts[i + 1] == 'mate') {
            // Mate score: convert to large eval
            final mateIn = int.tryParse(parts[i + 2]) ?? 0;
            scoreCP = mateIn > 0 ? 20000 - (mateIn * 10) : -20000 + (mateIn.abs() * 10);
          }
        }
      } else if (parts[i] == 'pv') {
        // Rest of the line is the PV
        pv.addAll(parts.sublist(i + 1));
        break;
      }
    }

    if (pv.isNotEmpty) {
      bestMove = pv[0];
    }

    return EngineEval(
      score: scoreCP / 100.0,
      depth: depth,
      bestMove: bestMove.isEmpty ? null : bestMove,
      pv: pv,
    );
  }

  EngineEval? get lastEval => _lastEval;

  Future<void> dispose() async {
    if (_instance != null) {
      _instance!.stdin = 'quit';
      await Future.delayed(const Duration(milliseconds: 100));
      _instance = null;
    }
  }
}
