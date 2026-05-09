import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/progress_repository.dart';

final activeProfileProvider =
    AsyncNotifierProvider<_ActiveProfileNotifier, UserProfile?>(
        _ActiveProfileNotifier.new);

class _ActiveProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final id = await ProgressRepository.instance.getActiveProfileId();
    if (id == null) return null;
    try {
      return UserProfile.all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> select(UserProfile profile) async {
    await ProgressRepository.instance.setActiveProfileId(profile.id);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    await ProgressRepository.instance.setActiveProfileId(null);
    state = const AsyncData(null);
  }
}
