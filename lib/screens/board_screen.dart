import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arrow.dart';
import '../models/opening_status.dart';
import '../providers/board_provider.dart';
import '../providers/opening_provider.dart';
import '../providers/engine_provider.dart';
import '../services/chess_service.dart';
import '../services/explanation_service.dart';
import '../services/stockfish_service.dart';
import '../widgets/board/chess_board_widget.dart';
import '../models/board_state.dart';
import '../widgets/banner_overlay.dart';
import '../widgets/eval_bar.dart';

// Desktop breakpoint — matches Chess.com's mobile/desktop split
const _kDesktop = 700.0;
const _kSidePanel = 320.0;
const _kEvalBar = 18.0;

final _panelOpenProvider = StateProvider<bool>((ref) => false);

// ── Entry point ───────────────────────────────────────────────────────────────

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(engineProvider.select((s) => s.isReady));
    final isDesktop = MediaQuery.of(context).size.width >= _kDesktop;
    return isDesktop ? const _DesktopLayout() : const _MobileLayout();
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Build engine arrows from top UCI moves when off-book.
List<Arrow> _engineArrows(List<String> uciMoves, String fen) {
  const ranks = [ArrowRank.gold, ArrowRank.silver, ArrowRank.bronze];
  final arrows = <Arrow>[];
  for (int i = 0; i < uciMoves.length && i < 3; i++) {
    final uci = uciMoves[i];
    if (uci.length < 4) continue;
    final san = ChessService.uciToSan(fen, uci) ?? uci;
    arrows.add(Arrow(
      fromSquare: uci.substring(0, 2),
      toSquare: uci.substring(2, 4),
      rank: ranks[i],
      san: san,
    ));
  }
  return arrows;
}

/// The board + eval bar, sized to fill whatever space is given.
class _BoardArea extends ConsumerWidget {
  const _BoardArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final status = ref.watch(boardProvider.select((s) => s.status));
    final fen = ref.watch(boardProvider.select((s) => s.fen));

    // Show engine arrows whenever the book has no arrows (off-book or complete)
    final extraArrows = (status == OpeningStatus.offBook || status == OpeningStatus.complete)
        ? _engineArrows(engine.topMovesUci, fen)
        : <Arrow>[];

    return LayoutBuilder(builder: (context, constraints) {
      final boardSize = min(
        constraints.maxWidth - _kEvalBar - 6,
        constraints.maxHeight - 4,
      ).clamp(100.0, 900.0);

      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _kEvalBar,
              height: boardSize,
              child: EvalBar(eval: engine.eval, isReady: engine.isReady),
            ),
            const SizedBox(width: 4),
            ChessBoardWidget(boardSize: boardSize, extraArrows: extraArrows),
          ],
        ),
      );
    });
  }
}

// ── Analysis panel content ────────────────────────────────────────────────────

class _AnalysisPanel extends ConsumerWidget {
  const _AnalysisPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final engine = ref.watch(engineProvider);
    final opening = ref.watch(selectedOpeningProvider);
    final moveList = ref.watch(moveListProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Analysis'),
              Tab(text: 'Moves'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // ── Analysis tab ──────────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AnalysisContent(boardState: boardState, engine: engine),
                      if (engine.isReady && engine.topMovesUci.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _EngineLines(
                          topMovesUci: engine.topMovesUci,
                          fen: boardState.fen,
                          eval: engine.eval,
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Moves tab ─────────────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opening?.name ?? 'Move List',
                        style: const TextStyle(
                          fontSize: 15,
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
                            fontSize: 14,
                            fontFamily: 'monospace',
                            height: 1.7,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Analysis content (in-book or off-book) ────────────────────────────────────

class _AnalysisContent extends StatelessWidget {
  final BoardState boardState;
  final EngineState engine;

  const _AnalysisContent({required this.boardState, required this.engine});

  @override
  Widget build(BuildContext context) {
    return switch (boardState.status) {
      OpeningStatus.complete => _emptyState(
          Icons.check_circle_outline,
          'Opening complete — engine analysis continues below.',
        ),
      OpeningStatus.offBook => _OffBookContent(engine: engine, fen: boardState.fen),
      OpeningStatus.inBook => boardState.arrows.isEmpty
          ? _emptyState(Icons.hourglass_empty, 'No suggestions for this position.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book moves',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...boardState.arrows.map<Widget>((a) => _BookMoveRow(arrow: a)),
              ],
            ),
    };
  }

  Widget _emptyState(IconData icon, String msg) => Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
        ],
      );
}

// ── Off-book commentary ───────────────────────────────────────────────────────

class _OffBookContent extends StatelessWidget {
  final EngineState engine;
  final String fen;

  const _OffBookContent({required this.engine, required this.fen});

  @override
  Widget build(BuildContext context) {
    final bestMoveSan = engine.eval?.bestMove != null
        ? ChessService.uciToSan(fen, engine.eval!.bestMove!)
        : null;
    final playerWasWhite = !ChessService.isWhiteTurn(fen);
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          explanation.detail,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.5),
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

// ── Engine top-3 lines ────────────────────────────────────────────────────────

class _EngineLines extends StatelessWidget {
  final List<String> topMovesUci;
  final String fen;
  final EngineEval? eval;

  const _EngineLines({
    required this.topMovesUci,
    required this.fen,
    required this.eval,
  });

  @override
  Widget build(BuildContext context) {
    const ranks = [ArrowRank.gold, ArrowRank.silver, ArrowRank.bronze];
    final labels = ['Best', 'Good', 'Alternative'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engine lines${eval != null ? ' · depth ${eval!.depth}' : ''}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(min(topMovesUci.length, 3), (i) {
          final san = ChessService.uciToSan(fen, topMovesUci[i]) ?? topMovesUci[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ranks[i].color,
                  ),
                ),
                Text(
                  san,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: ranks[i].color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── In-book move row ──────────────────────────────────────────────────────────

class _BookMoveRow extends StatelessWidget {
  final Arrow arrow;
  const _BookMoveRow({required this.arrow});

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
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: arrow.rank.color),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
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

// ── Desktop layout ────────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final opening = ref.watch(selectedOpeningProvider);
    final panelOpen = ref.watch(_panelOpenProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: ref.watch(boardProvider.select((s) => s.moveHistory.isNotEmpty))
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
              panelOpen ? Icons.analytics : Icons.analytics_outlined,
              color: panelOpen ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: panelOpen ? 'Hide panel' : 'Show analysis & moves',
            onPressed: () =>
                ref.read(_panelOpenProvider.notifier).state = !panelOpen,
          ),
          const SizedBox(width: 8),
        ],
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
                const Expanded(child: _BoardArea()),
                if (panelOpen)
                  Container(
                    width: _kSidePanel,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const _AnalysisPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final opening = ref.watch(selectedOpeningProvider);
    final canUndo = ref.watch(boardProvider.select((s) => s.moveHistory.isNotEmpty));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          BannerOverlay(
            status: boardState.status,
            openingName: opening?.name ?? '',
          ),
          const Expanded(child: _BoardArea()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 52,
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
                icon: const Icon(Icons.analytics_outlined),
                tooltip: 'Analysis & moves',
                onPressed: () => _showPanel(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, scrollController) => const _AnalysisPanel(),
        ),
      ),
    );
  }
}
