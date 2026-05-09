import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stockfish_service.dart';
import 'board_provider.dart';
import 'settings_provider.dart';

class EngineState {
  final EngineEval? eval;
  final EngineEval? prevEval;
  final List<String> topMovesUci; // Up to 3 UCI moves from MultiPV
  final bool isReady;

  const EngineState({
    this.eval,
    this.prevEval,
    this.topMovesUci = const [],
    this.isReady = false,
  });

  EngineState copyWith({
    EngineEval? eval,
    EngineEval? prevEval,
    List<String>? topMovesUci,
    bool? isReady,
    bool clearPrev = false,
    bool clearEval = false,
  }) => EngineState(
    eval: clearEval ? null : (eval ?? this.eval),
    prevEval: clearPrev ? null : (prevEval ?? this.prevEval),
    topMovesUci: topMovesUci ?? this.topMovesUci,
    isReady: isReady ?? this.isReady,
  );
}

class EngineNotifier extends Notifier<EngineState> {
  late final StockfishService _service;

  @override
  EngineState build() {
    _service = StockfishService();
    ref.onDispose(_service.dispose);
    _initAndListen();
    return const EngineState();
  }

  Future<void> _initAndListen() async {
    await _service.init();
    if (!_service.isReady) return;

    state = state.copyWith(isReady: true);

    ref.listen(boardProvider.select((s) => s.fen), (prev, next) {
      if (prev != next) {
        state = state.copyWith(prevEval: state.eval, topMovesUci: [], clearEval: true);
        _evaluate(next);
      }
    });

    ref.listen(engineDepthProvider, (prev, next) {
      if (prev?.valueOrNull != next.valueOrNull) {
        state = state.copyWith(topMovesUci: [], clearEval: true, clearPrev: true);
        _evaluate(ref.read(boardProvider).fen);
      }
    });

    _evaluate(ref.read(boardProvider).fen);
  }

  void _evaluate(String fen) {
    final depth = ref.read(engineDepthProvider).valueOrNull ?? kDefaultDepth;
    _service.evaluate(
      fen,
      depth: depth,
      onUpdate: (eval) => state = state.copyWith(eval: eval),
      onTopMoves: (moves) => state = state.copyWith(topMovesUci: moves),
    );
  }

  void stop() => _service.stop();
}

final engineProvider =
    NotifierProvider<EngineNotifier, EngineState>(EngineNotifier.new);
