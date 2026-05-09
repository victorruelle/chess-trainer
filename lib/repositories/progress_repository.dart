import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_session.dart';

class ProgressRepository {
  static ProgressRepository? _instance;
  static ProgressRepository get instance =>
      _instance ??= ProgressRepository._();
  ProgressRepository._();

  static const _activeKey = 'active_profile_id';
  static const _sessionsPrefix = 'sessions_';

  Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey);
  }

  Future<void> setActiveProfileId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeKey);
    } else {
      await prefs.setString(_activeKey, id);
    }
  }

  Future<List<TrainingSession>> getSessions(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_sessionsPrefix$profileId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((m) =>
            TrainingSession.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<void> saveSession(TrainingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions(session.profileId);
    sessions.removeWhere((s) => s.id == session.id);
    sessions.add(session);
    await prefs.setString(
      '$_sessionsPrefix${session.profileId}',
      jsonEncode(sessions.map((s) => s.toMap()).toList()),
    );
  }
}

// ── Computed mastery ───────────────────────────────────────────────────────────────────────

int computeStars(List<TrainingSession> sessions, String openingId) {
  final s = sessions.where((x) => x.openingId == openingId).toList();
  return _starsFromSessions(s);
}

int computeVariationStars(
    List<TrainingSession> sessions, String openingId, String? variation) {
  final s = sessions
      .where((x) => x.openingId == openingId && x.variation == variation)
      .toList();
  return _starsFromSessions(s);
}

int _starsFromSessions(List<TrainingSession> s) {
  if (s.isEmpty) return 0;
  final completions = s.where((x) => x.completed).length;
  // Partial sessions with ≥1 clean move count fractionally (accuracy × 0.5 each)
  // so that practicing without finishing still shows 1 star of progress.
  final effectiveCompletions = completions +
      s
          .where((x) => !x.completed && x.correctMoves >= 1)
          .fold(0.0, (sum, x) => sum + x.accuracy * 0.5);
  if (effectiveCompletions == 0) return 0;
  final bestAccuracy = s.map((x) => x.accuracy).reduce(max);
  final lastPracticed =
      s.map((x) => x.startedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  final daysSince = DateTime.now().difference(lastPracticed).inDays;

  // Stars 2+ require at least one full completion.
  int stars = 1;
  if (completions >= 1 && (completions >= 3 || bestAccuracy >= 0.7)) stars = max(stars, 2);
  if (completions >= 5 && bestAccuracy >= 0.8) stars = max(stars, 3);
  if (completions >= 8 && bestAccuracy >= 0.9) stars = max(stars, 4);
  if (completions >= 12 && bestAccuracy >= 0.95) stars = max(stars, 5);

  if (daysSince > 60) {
    stars = max(0, stars - 2);
  } else if (daysSince > 30) {
    stars = max(0, stars - 1);
  }

  return stars;
}

int computeStreak(List<TrainingSession> sessions) {
  if (sessions.isEmpty) return 0;
  final dates = sessions
      .map((s) =>
          DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final yesterdayNorm = todayNorm.subtract(const Duration(days: 1));

  if (!dates.contains(todayNorm) && !dates.contains(yesterdayNorm)) return 0;

  DateTime check =
      dates.contains(todayNorm) ? todayNorm : yesterdayNorm;
  int streak = 0;
  for (final d in dates) {
    if (d == check) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    } else if (d.isBefore(check)) {
      break;
    }
  }
  return streak;
}
