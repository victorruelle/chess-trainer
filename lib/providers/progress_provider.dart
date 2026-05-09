import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_session.dart';
import '../repositories/progress_repository.dart';
import 'profile_provider.dart';

final sessionsProvider =
    AsyncNotifierProvider<_SessionsNotifier, List<TrainingSession>>(
        _SessionsNotifier.new);

class _SessionsNotifier extends AsyncNotifier<List<TrainingSession>> {
  @override
  Future<List<TrainingSession>> build() async {
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    if (profile == null) return [];
    return ProgressRepository.instance.getSessions(profile.id);
  }

  Future<void> save(TrainingSession session) async {
    await ProgressRepository.instance.saveSession(session);
    ref.invalidateSelf();
  }
}

final starsForOpeningProvider =
    Provider.family<int, String>((ref, openingId) {
  final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
  return computeStars(sessions, openingId);
});
