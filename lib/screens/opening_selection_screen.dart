import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/opening_provider.dart';
import '../providers/board_provider.dart';
import '../widgets/color_selector.dart';
import '../widgets/opening_card.dart';
import 'board_screen.dart';

class OpeningSelectionScreen extends ConsumerWidget {
  const OpeningSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOpeningsAsync = ref.watch(allOpeningsProvider);
    final selectedColor = ref.watch(selectedColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Openings Trainer'),
        centerTitle: false,
      ),
      body: Column(
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
      ),
    );
  }
}
