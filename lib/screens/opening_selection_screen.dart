import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/opening_provider.dart';
import '../providers/board_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/color_selector.dart';
import '../widgets/opening_card.dart';
import 'board_screen.dart';
import 'profile_screen.dart';

class OpeningSelectionScreen extends ConsumerWidget {
  const OpeningSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _ensureProfileLoaded(ref);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chess Openings Trainer'),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.library_books_outlined), text: 'Openings'),
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OpeningsTab(),
            ProfileScreen(),
          ],
        ),
      ),
    );
  }

  void _ensureProfileLoaded(WidgetRef ref) {
    final active = ref.read(activeProfileProvider);
    if (active != null) return;
    final profilesAsync = ref.read(profilesProvider);
    profilesAsync.whenData((profiles) {
      if (profiles.isNotEmpty && ref.read(activeProfileProvider) == null) {
        ref.read(activeProfileProvider.notifier).state = profiles.first;
      }
    });
  }
}

// ── Openings tab ───────────────────────────────────────────────────────────────

class _OpeningsTab extends ConsumerWidget {
  const _OpeningsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOpeningsAsync = ref.watch(allOpeningsProvider);
    final selectedColor = ref.watch(selectedColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ColorSelector(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            selectedColor == null
                ? 'All openings'
                : selectedColor == 'white'
                    ? 'Openings for White'
                    : 'Openings for Black',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: allOpeningsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (openings) {
              final filtered = selectedColor == null
                  ? openings
                  : openings
                      .where((o) => o.color == selectedColor)
                      .toList();
              return ListView.builder(
                itemCount: filtered.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (ctx, i) => OpeningCard(
                  opening: filtered[i],
                  onTap: () {
                    ref.read(selectedOpeningProvider.notifier).state =
                        filtered[i];
                    ref.read(boardProvider.notifier).initForOpening();
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const BoardScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
