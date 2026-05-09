import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDepthKey = 'engine_depth';
const kDefaultDepth = 15;

final engineDepthProvider =
    AsyncNotifierProvider<_EngineDepthNotifier, int>(_EngineDepthNotifier.new);

class _EngineDepthNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDepthKey) ?? kDefaultDepth;
  }

  Future<void> setDepth(int depth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDepthKey, depth);
    state = AsyncData(depth);
  }
}
