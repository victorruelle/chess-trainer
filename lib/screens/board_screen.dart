import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arrow.dart';
import '../models/opening_status.dart';
import '../providers/board_provider.dart';
import '../providers/opening_provider.dart';
import '../providers/engine_provider.dart';
import '../services/chess_service.dart';
import '../services/explanation_service.dart';
import '../widgets/board/chess_board_widget.dart';
import '../widgets/banner_overlay.dart';
import '../widgets/eval_bar.dart';

final _explanationsOpenProvider = StateProvider<bool>((ref) => false);

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Touch engine provider immediately so Stockfish starts loading.
    ref.watch(engineProvider.select((s) => s.isReady));

    final boardState = ref.watch(boardProvider);
    final opening = ref.watch(selectedOpeningProvider);
    final panelOpen = ref.watch(_explanationsOpenProvider);

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
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Builder(builder: (context) {
                    final engine = ref.watch(engineProvider);
                    return EvalBar(eval: engine.eval, isReady: engine.isReady);
                  }),
                ),
                const Expanded(
                  child: Center(child: ChessBoardWidget()),
                ),
              ],
            ),
          ),
          if (panelOpen) const _ExplanationsPanel(),
          const _BottomControls(),
        ],
      ),
    );
  }
}

// ── Explanations panel ────────────────────────────────────────────────────────

class _ExplanationsPanel extends ConsumerWidget {
  const _ExplanationsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final engine = ref.watch(engineProvider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: switch (boardState.status) {
          OpeningStatus.complete => const _EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Opening complete — engine analysis continues above.',
            ),
          OpeningStatus.offBook => _OffBookPanel(engine: engine, boardFen: boardState.fen),
          OpeningStatus.inBook => boardState.arrows.isEmpty
              ? const _EmptyState(
                  icon: Icons.hourglass_empty,
                  message: 'No suggestions for this position.',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: boardState.arrows
                      .map((a) => _ExplanationRow(arrow: a))
                      .toList(),
                ),
        },
      ),
    );
  }
}

// ── Off-book panel ────────────────────────────────────────────────────────────

class _OffBookPanel extends StatelessWidget {
  final EngineState engine;
  final String boardFen;

  const _OffBookPanel({required this.engine, required this.boardFen});

  @override
  Widget build(BuildContext context) {
    // Convert engine best move from UCI to SAN for the *current* position.
    final bestMoveSan = engine.eval?.bestMove != null
        ? ChessService.uciToSan(boardFen, engine.eval!.bestMove!)
        : null;

    // The player who just moved is the one whose turn it is NOT right now.
    final playerWasWhite = !ChessService.isWhiteTurn(boardFen);

    final explanation = ExplanationService.explain(
      prevEval: engine.prevEval,
      currentEval: engine.eval,
      bestMoveSan: bestMoveSan,
      playerIsWhite: playerWasWhite,
    );

    final severityColor = switch (explanation.severity) {
      Severity.blunder => Colors.red.shade700,
      Severity.mistake => Colors.orange.shade700,
      Severity.inaccuracy => Colors.amber.shade700,
      Severity.neutral => Colors.blue.shade700,
    };

    final severityIcon = switch (explanation.severity) {
      Severity.blunder => Icons.dangerous_outlined,
      Severity.mistake => Icons.warning_amber_rounded,
      Severity.inaccuracy => Icons.info_outline,
      Severity.neutral => Icons.route_outlined,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: icon + verdict + eval badge
        Row(
          children: [
            Icon(severityIcon, size: 18, color: severityColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                explanation.verdict,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: severityColor,
                ),
              ),
            ),
            if (explanation.evalDisplay != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  explanation.evalDisplay!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Detail text
        Text(
          explanation.detail,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
        if (explanation.depth != null) ...[
          const SizedBox(height: 6),
          Text(
            'Engine depth: ${explanation.depth}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }
}

// ── In-book explanation row ───────────────────────────────────────────────────

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
                  const SizedBox(height: 3),
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

// ── Empty state ───────────────────────────────────────────────────────────────

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

// ── Bottom controls ───────────────────────────────────────────────────────────

class _BottomControls extends ConsumerWidget {
  const _BottomControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canUndo = ref.watch(
      boardProvider.select((s) => s.moveHistory.isNotEmpty),
    );
    final panelOpen = ref.watch(_explanationsOpenProvider);
    final status = ref.watch(boardProvider.select((s) => s.status));
    final hasArrows = ref.watch(boardProvider.select((s) => s.arrows.isNotEmpty));

    // Lightbulb is available in-book (arrows) and off-book (engine explanation).
    final lightbulbAvailable =
        status == OpeningStatus.offBook || (status == OpeningStatus.inBook && hasArrows);

    return SafeArea(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
                    : lightbulbAvailable
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
              ),
              tooltip: panelOpen ? 'Hide analysis' : 'Show analysis',
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
