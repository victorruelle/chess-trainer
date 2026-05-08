import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stockfish_service.dart';
import 'board_provider.dart';

final stockfishServiceProvider = Provider<StockfishService>((ref) {
  return StockfishService();
});

final engineStateProvider = StateProvider<EngineEval?>((ref) => null);
final engineDepthProvider = StateProvider<int>((ref) => 0);

// Initialize Stockfish on app startup
final engineInitProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(stockfishServiceProvider);
  await service.init();
});

// Trigger engine evaluation when board FEN changes
final engineEvaluationProvider = FutureProvider<void>((ref) async {
  await ref.watch(engineInitProvider.future);

  final boardState = ref.watch(boardProvider);
  final service = ref.watch(stockfishServiceProvider);

  // Evaluate position with depth 18 (adjust as needed for performance)
  final eval = await service.evaluatePosition(boardState.fen, depth: 18);

  if (eval != null) {
    ref.read(engineStateProvider.notifier).state = eval;
    ref.read(engineDepthProvider.notifier).state = eval.depth;
  }
});
