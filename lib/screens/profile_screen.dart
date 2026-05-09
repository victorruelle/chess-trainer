import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_session.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../repositories/progress_repository.dart';
import '../screens/board_screen.dart' show StarRating;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);

    if (activeProfile == null) {
      return _NoProfileView(
        onCreate: (name) => _createProfile(context, ref, name),
      );
    }

    final sessionsAsync = ref.watch(sessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: \$e')),
      data: (sessions) => _ProfileView(
        profileName: activeProfile.name,
        sessions: sessions,
        onSwitchProfile: () => _showProfilePicker(context, ref),
      ),
    );
  }

  Future<void> _createProfile(
      BuildContext context, WidgetRef ref, String name) async {
    final profile =
        await ref.read(profilesProvider.notifier).createProfile(name);
    ref.read(activeProfileProvider.notifier).state = profile;
  }

  void _showProfilePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProfilePickerSheet(
        onCreateNew: (name) => _createProfile(context, ref, name),
      ),
    );
  }
}

// ── No profile yet ───────────────────────────────────────────────────────

class _NoProfileView extends StatefulWidget {
  final Future<void> Function(String name) onCreate;
  const _NoProfileView({required this.onCreate});

  @override
  State<_NoProfileView> createState() => _NoProfileViewState();
}

class _NoProfileViewState extends State<_NoProfileView> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    await widget.onCreate(name);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          const Text('Create your profile',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Track your progress, mastery, and streaks across openings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create profile'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile picker sheet ─────────────────────────────────────────────────────

class _ProfilePickerSheet extends ConsumerStatefulWidget {
  final Future<void> Function(String name) onCreateNew;
  const _ProfilePickerSheet({required this.onCreateNew});

  @override
  ConsumerState<_ProfilePickerSheet> createState() =>
      _ProfilePickerSheetState();
}

class _ProfilePickerSheetState
    extends ConsumerState<_ProfilePickerSheet> {
  final _ctrl = TextEditingController();
  bool _showCreate = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? [];
    final active = ref.watch(activeProfileProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Switch profile',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...profiles.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(p.name[0].toUpperCase())),
                title: Text(p.name),
                trailing: p.id == active?.id
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(activeProfileProvider.notifier).state = p;
                  Navigator.pop(context);
                },
              )),
          const Divider(),
          if (!_showCreate)
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New profile'),
              onPressed: () => setState(() => _showCreate = true),
            )
          else ...[
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _showCreate = false),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    final name = _ctrl.text.trim();
                    if (name.isEmpty) return;
                    await widget.onCreateNew(name);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Main profile view ─────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  final String profileName;
  final List<TrainingSession> sessions;
  final VoidCallback onSwitchProfile;

  const _ProfileView({
    required this.profileName,
    required this.sessions,
    required this.onSwitchProfile,
  });

  @override
  Widget build(BuildContext context) {
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
            name: profileName,
            streak: streak,
            totalSessions: totalSessions,
            completedSessions: completedSessions,
            onSwitchProfile: onSwitchProfile,
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
                    Text('No training sessions yet',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade500)),
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

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final int streak;
  final int totalSessions;
  final int completedSessions;
  final VoidCallback onSwitchProfile;

  const _ProfileHeader({
    required this.name,
    required this.streak,
    required this.totalSessions,
    required this.completedSessions,
    required this.onSwitchProfile,
  });

  @override
  Widget build(BuildContext context) {
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
                  name[0].toUpperCase(),
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
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                        '\$totalSessions sessions · \$completedSessions completions',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSwitchProfile,
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
                    '\$streak-day streak',
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

// ── Opening progress card ────────────────────────────────────────────────────

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
    final completions = widget.sessions.where((s) => s.completed).length;
    final lastSession = widget.sessions
        .map((s) => s.startedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final daysSince = DateTime.now().difference(lastSession).inDays;
    final lastLabel = daysSince == 0
        ? 'Today'
        : daysSince == 1
            ? 'Yesterday'
            : '\$daysSince days ago';

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
                              '\$completions completion\${completions == 1 ? '' : 's'} · \$lastLabel',
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
                      _expanded ? Icons.expand_less : Icons.expand_more,
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
              final vCompletions = e.value.where((s) => s.completed).length;
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
                            '\$vCompletions completion\${vCompletions == 1 ? '' : 's'}',
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
