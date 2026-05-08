import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stockfish_service.dart';
import 'board_provider.dart';

// ── Engine state ──────────────────────────────────────────────────────────────

class EngineState {
  final EngineEval? eval;
  /// Snapshot of eval at the position *before* the most recent move.
  /// Used to compute the cost of off-book deviations.
  final EngineEval? prevEval;
  final bool isReady;

  const EngineState({
    this.eval,
    this.prevEval,
    this.isReady = false,
  });

  EngineState copyWith({
    EngineEval? eval,
    EngineEval? prevEval,
    bool? isReady,
    bool clearPrev = false,
  }) => EngineState(
    eval: eval ?? this.eval,
    prevEval: clearPrev ? null : (prevEval ?? this.prevEval),
    isReady: isReady ?? this.isReady,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

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

    // Every time the board FEN changes, snapshot the current eval as prevEval
    // then kick off a new search.
    ref.listen(boardProvider.select((s) => s.fen), (prev, next) {
      if (prev != next) {
        state = state.copyWith(prevEval: state.eval);
        _evaluate(next);
      }
    });

    _evaluate(ref.read(boardProvider).fen);
  }

  void _evaluate(String fen) {
    _service.evaluate(
      fen,
      depth: 20,
      onUpdate: (eval) {
        state = state.copyWith(eval: eval);
      },
    );
  }

  void stop() => _service.stop();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final engineProvider =
    NotifierProvider<EngineNotifier, EngineState>(EngineNotifier.new);
