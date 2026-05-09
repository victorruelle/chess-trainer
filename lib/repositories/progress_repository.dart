import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';
import '../models/training_session.dart';

class ProgressRepository {
  static ProgressRepository? _instance;
  static ProgressRepository get instance =>
      _instance ??= ProgressRepository._();
  ProgressRepository._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'chess_trainer.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE training_sessions (
            id TEXT PRIMARY KEY,
            profileId TEXT NOT NULL,
            openingId TEXT NOT NULL,
            openingName TEXT NOT NULL,
            variation TEXT,
            correctMoves INTEGER NOT NULL,
            totalMoves INTEGER NOT NULL,
            completed INTEGER NOT NULL,
            startedAt INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  // ── Profiles ─────────────────────────────────────────────────────────────

  Future<List<UserProfile>> getProfiles() async {
    final db = await _database;
    final rows = await db.query('profiles', orderBy: 'createdAt ASC');
    return rows.map(UserProfile.fromMap).toList();
  }

  Future<void> saveProfile(UserProfile p) async {
    final db = await _database;
    await db.insert('profiles', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProfile(String id) async {
    final db = await _database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
    await db.delete('training_sessions',
        where: 'profileId = ?', whereArgs: [id]);
  }

  // ── Sessions ─────────────────────────────────────────────────────────────

  Future<void> saveSession(TrainingSession s) async {
    final db = await _database;
    await db.insert('training_sessions', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TrainingSession>> getSessionsForProfile(String profileId) async {
    final db = await _database;
    final rows = await db.query(
      'training_sessions',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'startedAt DESC',
    );
    return rows.map(TrainingSession.fromMap).toList();
  }
}

// ── Computed mastery ───────────────────────────────────────────────────────

/// Returns 0–5 stars for an opening (aggregate across all its variations).
int computeStars(List<TrainingSession> sessions, String openingId) {
  final s = sessions.where((x) => x.openingId == openingId).toList();
  return _starsFromSessions(s);
}

/// Returns 0–5 stars for a specific (opening, variation) pair.
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
  if (completions == 0) return 0;
  final bestAccuracy = s.map((x) => x.accuracy).reduce(max);
  final lastPracticed =
      s.map((x) => x.startedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  final daysSince = DateTime.now().difference(lastPracticed).inDays;

  int stars = 1;
  if (completions >= 3 || bestAccuracy >= 0.7) stars = max(stars, 2);
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

/// Returns current daily streak (≥1 session per consecutive day).
int computeStreak(List<TrainingSession> sessions) {
  if (sessions.isEmpty) return 0;
  final dates = sessions
      .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final yesterdayNorm = todayNorm.subtract(const Duration(days: 1));

  if (!dates.contains(todayNorm) && !dates.contains(yesterdayNorm)) return 0;

  DateTime check = dates.contains(todayNorm) ? todayNorm : yesterdayNorm;
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
