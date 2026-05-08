import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arrow.dart';
import '../models/opening_status.dart';
import '../providers/board_provider.dart';
import '../providers/opening_provider.dart';
import '../widgets/board/chess_board_widget.dart';
import '../widgets/banner_overlay.dart';

final _explanationsOpenProvider = StateProvider<bool>((ref) => false);

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final opening = ref.watch(selectedOpeningProvider);
    final panelOpen = ref.watch(_explanationsOpenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(opening?.name ?? 'Opening Trainer'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          if (panelOpen)
            _ExplanationsPanel(
              arrows: boardState.arrows,
              status: boardState.status,
            ),
          _BottomControls(),
        ],
      ),
    );
  }
}

class _ExplanationsPanel extends StatelessWidget {
  final List<Arrow> arrows;
  final OpeningStatus status;

  const _ExplanationsPanel({required this.arrows, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _panelContent(),
      ),
    );
  }

  Widget _panelContent() {
    if (status == OpeningStatus.offBook) {
      return const _EmptyState(
        icon: Icons.route_outlined,
        message: "You're off-book — no opening guidance available.",
      );
    }
    if (status == OpeningStatus.complete) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        message: 'Opening complete. Play freely from here.',
      );
    }
    if (arrows.isEmpty) {
      return const _EmptyState(
        icon: Icons.hourglass_empty,
        message: 'No suggestions for this position.',
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: arrows.map((arrow) => _ExplanationRow(arrow: arrow)).toList(),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4, right: 10),
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
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rankLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: arrow.rank.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (arrow.explanation != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    arrow.explanation!,
                    style: TextStyle(
                      fontSize: 13,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
    final panelOpen = ref.watch(_explanationsOpenProvider);
    final boardState = ref.watch(boardProvider);
    final hasExplanations =
        boardState.status == OpeningStatus.inBook && boardState.arrows.isNotEmpty;

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
              icon: Icon(
                panelOpen ? Icons.lightbulb : Icons.lightbulb_outline,
                color: panelOpen
                    ? const Color(0xFFFFD700)
                    : hasExplanations
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
              ),
              tooltip: 'Move ideas',
              onPressed: () => ref
                  .read(_explanationsOpenProvider.notifier)
                  .state = !panelOpen,
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
