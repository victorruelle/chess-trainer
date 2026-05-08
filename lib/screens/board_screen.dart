import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              opening?.name ?? 'Opening Trainer',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (boardState.variation != null)
              Text(
                boardState.variation!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
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
          _BottomControls(),
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
