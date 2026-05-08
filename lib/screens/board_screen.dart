import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arrow.dart';
import '../models/opening_status.dart';
import '../providers/board_provider.dart';
import '../providers/opening_provider.dart';
import '../widgets/board/chess_board_widget.dart';
import '../widgets/banner_overlay.dart';

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final opening = ref.watch(selectedOpeningProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(opening?.name ?? 'Opening Trainer'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _LightbulbButton(
            arrows: boardState.arrows,
            status: boardState.status,
            openingName: opening?.name ?? '',
          ),
        ],
      ),
      body: Column(
        children: [
          BannerOverlay(
            status: boardState.status,
            openingName: opening?.name ?? '',
          ),
          const Expanded(
            child: Center(
              child: ChessBoardWidget(),
            ),
          ),
          _BottomControls(),
        ],
      ),
    );
  }
}

class _LightbulbButton extends StatelessWidget {
  final List<Arrow> arrows;
  final OpeningStatus status;
  final String openingName;

  const _LightbulbButton({
    required this.arrows,
    required this.status,
    required this.openingName,
  });

  @override
  Widget build(BuildContext context) {
    final hasExplanations =
        status == OpeningStatus.inBook && arrows.isNotEmpty;

    return IconButton(
      icon: Icon(
        hasExplanations ? Icons.lightbulb : Icons.lightbulb_outline,
        color: hasExplanations
            ? const Color(0xFFFFD700)
            : Colors.grey.shade400,
      ),
      tooltip: 'Move explanations',
      onPressed: () => _showExplanations(context),
    );
  }

  void _showExplanations(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ExplanationsSheet(
        arrows: arrows,
        status: status,
        openingName: openingName,
      ),
    );
  }
}

class _ExplanationsSheet extends StatelessWidget {
  final List<Arrow> arrows;
  final OpeningStatus status;
  final String openingName;

  const _ExplanationsSheet({
    required this.arrows,
    required this.status,
    required this.openingName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Move Ideas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            openingName,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (status == OpeningStatus.offBook)
            const _EmptyState(
              icon: Icons.route_outlined,
              message: "You're off-book — no opening guidance available.",
            )
          else if (status == OpeningStatus.complete)
            const _EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Opening complete. Play freely from here.',
            )
          else if (arrows.isEmpty)
            const _EmptyState(
              icon: Icons.hourglass_empty,
              message: 'No suggestions for this position.',
            )
          else
            ...arrows.map((arrow) => _ExplanationRow(arrow: arrow)),
        ],
      ),
    );
  }
}

class _ExplanationRow extends StatelessWidget {
  final Arrow arrow;

  const _ExplanationRow({required this.arrow});

  @override
  Widget build(BuildContext context) {
    final rankLabel = switch (arrow.rank) {
      ArrowRank.gold => 'Best',
      ArrowRank.silver => 'Good',
      ArrowRank.bronze => 'Also good',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5, right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: arrow.rank.color,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      arrow.san,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rankLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: arrow.rank.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (arrow.explanation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    arrow.explanation!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(
      boardProvider.select((s) => s.moveHistory.isNotEmpty),
    );

    return SafeArea(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: canUndo
                  ? () => ref.read(boardProvider.notifier).undo()
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
              onPressed: () => ref.read(boardProvider.notifier).reset(),
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'Move list',
              onPressed: () => _showMoveList(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveList(BuildContext context, WidgetRef ref) {
    final moveList = ref.read(moveListProvider);
    final opening = ref.read(selectedOpeningProvider);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                opening?.name ?? 'Move List',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (moveList.isEmpty)
                Text(
                  'No moves played yet.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                Text(
                  moveList,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'monospace',
                    height: 1.6,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
