import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stockfish_service.dart';
import 'board_provider.dart';

// ── Engine state ──────────────────────────────────────────────────────────────

class EngineState {
  final EngineEval? eval;
  final bool isReady;
  final bool isSearching;

  const EngineState({
    this.eval,
    this.isReady = false,
    this.isSearching = false,
  });

  EngineState copyWith({EngineEval? eval, bool? isReady, bool? isSearching}) =>
      EngineState(
        eval: eval ?? this.eval,
        isReady: isReady ?? this.isReady,
        isSearching: isSearching ?? this.isSearching,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class EngineNotifier extends Notifier<EngineState> {
  late final StockfishService _service;

  @override
  EngineState build() {
    _service = StockfishService();

    // Kick off init asynchronously; state will update when ready
    _initAndListen();

    ref.onDispose(_service.dispose);

    return const EngineState();
  }

  Future<void> _initAndListen() async {
    await _service.init();
    if (!_service.isReady) return;

    state = state.copyWith(isReady: true);

    // Watch board FEN — re-evaluate every time a move is played
    ref.listen(boardProvider.select((s) => s.fen), (prev, next) {
      if (prev != next) _evaluate(next);
    });

    // Evaluate the starting position immediately
    _evaluate(ref.read(boardProvider).fen);
  }

  void _evaluate(String fen) {
    state = state.copyWith(isSearching: true);
    _service.evaluate(
      fen,
      depth: 20,
      onUpdate: (eval) {
        state = state.copyWith(eval: eval, isSearching: true);
      },
    );
  }

  void stop() => _service.stop();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final engineProvider =
    NotifierProvider<EngineNotifier, EngineState>(EngineNotifier.new);
