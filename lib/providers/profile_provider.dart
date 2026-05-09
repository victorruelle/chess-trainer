import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/progress_repository.dart';

final profilesProvider =
    AsyncNotifierProvider<_ProfilesNotifier, List<UserProfile>>(
        _ProfilesNotifier.new);

class _ProfilesNotifier extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() =>
      ProgressRepository.instance.getProfiles();

  Future<UserProfile> createProfile(String name) async {
    final p = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    await ProgressRepository.instance.saveProfile(p);
    ref.invalidateSelf();
    await future;
    return p;
  }

  Future<void> deleteProfile(String id) async {
    await ProgressRepository.instance.deleteProfile(id);
    final active = ref.read(activeProfileProvider);
    if (active?.id == id) {
      ref.read(activeProfileProvider.notifier).state = null;
    }
    ref.invalidateSelf();
  }
}

final activeProfileProvider = StateProvider<UserProfile?>((ref) => null);
