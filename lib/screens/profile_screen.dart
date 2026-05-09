import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/training_session.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../repositories/progress_repository.dart';
import '../screens/board_screen.dart' show StarRating;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (activeProfile) {
        if (activeProfile == null) {
          return const _ProfilePickerView();
        }
        return ref.watch(sessionsProvider).when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (sessions) => _ProfileView(
                profile: activeProfile,
                sessions: sessions,
              ),
            );
      },
    );
  }
}

// ── Netflix-style profile picker ────────────────────────────────────────────────────

class _ProfilePickerView extends StatelessWidget {
  const _ProfilePickerView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Who's playing?",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: UserProfile.all
                .map((p) => _ProfileTile(profile: p))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  final UserProfile profile;
  const _ProfileTile({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () =>
          ref.read(activeProfileProvider.notifier).select(profile),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                profile.name[0],
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main profile view ───────────────────────────────────────────────────────────────────────

class _ProfileView extends ConsumerWidget {
  final UserProfile profile;
  final List<TrainingSession> sessions;

  const _ProfileView({required this.profile, required this.sessions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = computeStreak(sessions);
    final totalSessions = sessions.length;
    final completedSessions = sessions.where((s) => s.completed).length;

    final Map<String, List<TrainingSession>> byOpening = {};
    for (final s in sessions) {
      byOpening.putIfAbsent(s.openingId, () => []).add(s);
    }
    final practicedOpenings = byOpening.keys.toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProfileHeader(
            profile: profile,
            streak: streak,
            totalSessions: totalSessions,
            completedSessions: completedSessions,
          ),
        ),
        if (practicedOpenings.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_outlined,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No training sessions yet',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick an opening and train in Training mode\nto start tracking progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final openingId = practicedOpenings[i];
                  final openingSessions = byOpening[openingId]!;
                  return _OpeningProgressCard(
                    openingId: openingId,
                    openingName: openingSessions.first.openingName,
                    sessions: openingSessions,
                  );
                },
                childCount: practicedOpenings.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Profile header ──────────────────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  final UserProfile profile;
  final int streak;
  final int totalSessions;
  final int completedSessions;

  const _ProfileHeader({
    required this.profile,
    required this.streak,
    required this.totalSessions,
    required this.completedSessions,
  });

  void _showSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Switch profile",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: UserProfile.all.map((p) {
                final isActive = p.id == profile.id;
                final color =
                    Theme.of(context).colorScheme.primary;
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(activeProfileProvider.notifier)
                        .select(p);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: isActive
                                  ? color.withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                              child: Text(
                                p.name[0],
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? color
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            if (isActive)
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: color,
                                child: const Icon(Icons.check,
                                    size: 13, color: Colors.white),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primary.withValues(alpha: 0.15),
                child: Text(
                  profile.name[0].toUpperCase(),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                      '$totalSessions sessions · $completedSessions completions',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showSwitcher(context, ref),
                child: const Text('Switch'),
              ),
            ],
          ),
          if (streak > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    '$streak-day streak',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Opening progress card ───────────────────────────────────────────────────────────────────────────────────

class _OpeningProgressCard extends StatefulWidget {
  final String openingId;
  final String openingName;
  final List<TrainingSession> sessions;

  const _OpeningProgressCard({
    required this.openingId,
    required this.openingName,
    required this.sessions,
  });

  @override
  State<_OpeningProgressCard> createState() =>
      _OpeningProgressCardState();
}

class _OpeningProgressCardState extends State<_OpeningProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stars = computeStars(widget.sessions, widget.openingId);
    final completions =
        widget.sessions.where((s) => s.completed).length;
    final lastSession = widget.sessions
        .map((s) => s.startedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final daysSince =
        DateTime.now().difference(lastSession).inDays;
    final lastLabel = daysSince == 0
        ? 'Today'
        : daysSince == 1
            ? 'Yesterday'
            : '$daysSince days ago';

    final Map<String?, List<TrainingSession>> byVariation = {};
    for (final s in widget.sessions) {
      byVariation.putIfAbsent(s.variation, () => []).add(s);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: byVariation.length > 1
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.openingName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StarRating(stars: stars),
                            const SizedBox(width: 10),
                            Text(
                              '$completions completion${completions == 1 ? "" : "s"} · $lastLabel',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (byVariation.length > 1)
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.grey.shade500,
                    ),
                ],
              ),
            ),
          ),
          if (_expanded && byVariation.length > 1) ...[
            const Divider(height: 1),
            ...byVariation.entries.map((e) {
              final vStars = computeVariationStars(
                  widget.sessions, widget.openingId, e.key);
              final vCompletions =
                  e.value.where((s) => s.completed).length;
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key ?? 'Main line',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$vCompletions completion${vCompletions == 1 ? "" : "s"}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    StarRating(stars: vStars, size: 13),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
