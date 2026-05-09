import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stockfish_service.dart';
import 'board_provider.dart';

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
  }) => EngineState(
    eval: eval ?? this.eval,
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
        state = state.copyWith(prevEval: state.eval, topMovesUci: []);
        _evaluate(next);
      }
    });

    _evaluate(ref.read(boardProvider).fen);
  }

  void _evaluate(String fen) {
    _service.evaluate(
      fen,
      depth: 20,
      onUpdate: (eval) => state = state.copyWith(eval: eval),
      onTopMoves: (moves) => state = state.copyWith(topMovesUci: moves),
    );
  }

  void stop() => _service.stop();
}

final engineProvider =
    NotifierProvider<EngineNotifier, EngineState>(EngineNotifier.new);
