import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arrow.dart';
import '../models/board_state.dart';
import '../models/opening_status.dart';
import '../providers/board_provider.dart';
import '../providers/opening_provider.dart';
import '../providers/engine_provider.dart';
import '../services/chess_service.dart';
import '../services/explanation_service.dart';
import '../services/stockfish_service.dart';
import '../widgets/board/chess_board_widget.dart';
import '../widgets/eval_bar.dart';

const _kDesktop = 700.0;
const _kSidePanel = 320.0;
const _kEvalBar = 18.0;
const _kMinPanel = 200.0;
const _kMaxPanel = 460.0;

final _panelOpenProvider = StateProvider<bool>((ref) => false);
final _boardFlippedProvider = StateProvider<bool>((ref) => false);
final _trainingModeProvider = StateProvider<bool>((ref) => false);

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

// ── AppBar title with inline status chip ─────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  final String name;
  final String? variation;
  final OpeningStatus status;

  const _AppBarTitle({
    required this.name,
    required this.variation,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final chip = switch (status) {
      OpeningStatus.offBook => _StatusChip(
          label: 'Off book',
          color: Colors.orange.shade700,
          bg: Colors.orange.shade100,
        ),
      OpeningStatus.complete => _StatusChip(
          label: 'Complete',
          color: Colors.green.shade700,
          bg: Colors.green.shade100,
        ),
      OpeningStatus.inBook => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chip != null) ...[const SizedBox(width: 8), chip],
          ],
        ),
        if (variation != null)
          Text(
            variation!,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
              fontWeight: FontWeight.normal,
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Build engine arrows, validating each move against the CURRENT fen so stale
/// arrows from a previous position are never shown after a move is played.
List<Arrow> _engineArrows(List<String> uciMoves, String fen) {
  const ranks = [ArrowRank.gold, ArrowRank.silver, ArrowRank.bronze];
  final arrows = <Arrow>[];
  for (int i = 0; i < uciMoves.length && i < 3; i++) {
    final uci = uciMoves[i];
    if (uci.length < 4) continue;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    // Skip if this move is not legal in the current position (stale from prev pos)
    if (!ChessService.isLegalMove(fen, from, to)) continue;
    final san = ChessService.uciToSan(fen, uci) ?? uci;
    arrows.add(Arrow(fromSquare: from, toSquare: to, rank: ranks[i], san: san));
  }
  return arrows;
}

// ── Board area (shared) ───────────────────────────────────────────────────────

class _BoardArea extends ConsumerWidget {
  const _BoardArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final status = ref.watch(boardProvider.select((s) => s.status));
    final fen = ref.watch(boardProvider.select((s) => s.fen));
    final flipped = ref.watch(_boardFlippedProvider);
    final training = ref.watch(_trainingModeProvider);

    // In training mode: no arrows at all — player must find the best move
    final extraArrows = (!training &&
            (status == OpeningStatus.offBook ||
                status == OpeningStatus.complete))
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
            ChessBoardWidget(
              boardSize: boardSize,
              extraArrows: extraArrows,
              hideBookArrows: training,
              flipped: flipped,
            ),
          ],
        ),
      );
    });
  }
}

// ── Analysis panel content (used in both desktop side panel and mobile sheet) ─

class _AnalysisPanel extends ConsumerWidget {
  const _AnalysisPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final engine = ref.watch(engineProvider);
    final opening = ref.watch(selectedOpeningProvider);
    final moveList = ref.watch(moveListProvider);
    final training = ref.watch(_trainingModeProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Mode toggle ─────────────────────────────────────────────
          _ModeToggle(training: training),
          TabBar(
            tabs: const [Tab(text: 'Analysis'), Tab(text: 'Moves')],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey.shade600,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // ── Analysis tab ────────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (training) ...[
                        _TrainingFeedback(
                          boardState: boardState,
                          engine: engine,
                        ),
                      ] else ...[
                        _AnalysisContent(boardState: boardState, engine: engine),
                        if (engine.isReady &&
                            (boardState.status == OpeningStatus.offBook ||
                                boardState.status == OpeningStatus.complete)) ...[
                          const SizedBox(height: 16),
                          _EngineLines(
                            topMovesUci: engine.topMovesUci,
                            fen: boardState.fen,
                            eval: engine.eval,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                // ── Moves tab ───────────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opening?.name ?? 'Move List',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      moveList.isEmpty
                          ? Text('No moves played yet.',
                              style: TextStyle(color: Colors.grey.shade600))
                          : Text(
                              moveList,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                  height: 1.7),
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

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends ConsumerWidget {
  final bool training;
  const _ModeToggle({required this.training});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: _ModeChip(
              label: 'Learning',
              icon: Icons.visibility,
              active: !training,
              onTap: () => ref.read(_trainingModeProvider.notifier).state = false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeChip(
              label: 'Training',
              icon: Icons.visibility_off,
              active: training,
              onTap: () => ref.read(_trainingModeProvider.notifier).state = true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? primary.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: active ? primary : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: active ? primary : Colors.grey.shade500),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Training feedback ─────────────────────────────────────────────────────────

class _TrainingFeedback extends StatelessWidget {
  final BoardState boardState;
  final EngineState engine;
  const _TrainingFeedback({required this.boardState, required this.engine});

  @override
  Widget build(BuildContext context) {
    final eval = boardState.lastMoveEval;

    if (eval == null) {
      // No move played yet — prompt the player
      final turn = ChessService.isWhiteTurn(boardState.fen) ? 'White' : 'Black';
      return _prompt(context, 'Find the best move for $turn');
    }

    return switch (eval.quality) {
      MoveQuality.correct => _correctCard(context, eval.playedSan),
      MoveQuality.alternative => _alternativeCard(context, eval),
      MoveQuality.offBook => _offBookCard(context, eval),
    };
  }

  Widget _prompt(BuildContext context, String text) {
    return Row(
      children: [
        Icon(Icons.help_outline, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _correctCard(BuildContext context, String san) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text(
              '$san — main line!',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.green.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Exactly right. Keep going — what\'s next?',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _alternativeCard(BuildContext context, MoveEval eval) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.fork_right, size: 18, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            Text(
              '${eval.playedSan} — you entered a variant!',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.teal.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'This is a fully valid path through the opening. '
          'The main line goes ${eval.bestSan} — exploring variants is how you really learn!',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _offBookCard(BuildContext context, MoveEval eval) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                eval.bestSan != null
                    ? '${eval.playedSan} — not the book move'
                    : '${eval.playedSan} — off book territory',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.red.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        if (eval.bestSan != null) ...[
          const SizedBox(height: 6),
          Text(
            'The main line was ${eval.bestSan}. '
            'Switch to Learning mode to see the arrows and study the position.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
        // Also show engine analysis so the player understands how bad/good it was
        if (engine.isReady) ...[
          const SizedBox(height: 16),
          _OffBookContent(engine: engine, fen: boardState.fen),
        ],
      ],
    );
  }
}

// ── Analysis content ──────────────────────────────────────────────────────────

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
      OpeningStatus.offBook =>
        _OffBookContent(engine: engine, fen: boardState.fen),
      OpeningStatus.inBook => boardState.arrows.isEmpty
          ? _emptyState(
              Icons.hourglass_empty, 'No suggestions for this position.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOOK MOVES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...boardState.arrows
                    .map<Widget>((a) => _BookMoveRow(arrow: a)),
              ],
            ),
    };
  }

  Widget _emptyState(IconData icon, String msg) => Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
    if (engine.eval == null) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Analysing position…',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      );
    }

    final bestMoveSan = engine.eval!.bestMove != null
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
              child: Text(explanation.verdict,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: severityColor)),
            ),
            if (explanation.evalDisplay != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(explanation.detail,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade800, height: 1.5)),
        if (explanation.depth != null) ...[
          const SizedBox(height: 6),
          Text('Engine depth: ${explanation.depth}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
  const _EngineLines(
      {required this.topMovesUci, required this.fen, required this.eval});

  @override
  Widget build(BuildContext context) {
    const ranks = [ArrowRank.gold, ArrowRank.silver, ArrowRank.bronze];
    const labels = ['Best', 'Good', 'Alternative'];

    if (topMovesUci.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENGINE LINES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Calculating…',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENGINE LINES${eval != null ? ' · depth ${eval!.depth}' : ''}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(min(topMovesUci.length, 3), (i) {
          final san =
              ChessService.uciToSan(fen, topMovesUci[i]) ?? topMovesUci[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: ranks[i].color),
                ),
                Text(san,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(width: 6),
                Text(labels[i],
                    style: TextStyle(
                        fontSize: 11,
                        color: ranks[i].color,
                        fontWeight: FontWeight.w600)),
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
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: arrow.rank.color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(arrow.san,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'monospace')),
                  const SizedBox(width: 6),
                  Text(rankLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: arrow.rank.color,
                          fontWeight: FontWeight.w600)),
                ]),
                if (arrow.explanation != null) ...[
                  const SizedBox(height: 3),
                  Text(arrow.explanation!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4)),
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
    final flipped = ref.watch(_boardFlippedProvider);
    final training = ref.watch(_trainingModeProvider);
    final canUndo =
        ref.watch(boardProvider.select((s) => s.moveHistory.isNotEmpty));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (canUndo) ref.read(boardProvider.notifier).undo();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _AppBarTitle(
          name: opening?.name ?? 'Opening Trainer',
          variation: boardState.variation,
          status: boardState.status,
        ),
        centerTitle: false,
        actions: [
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
              Icons.swap_vert,
              color: flipped ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: 'Flip board',
            onPressed: () =>
                ref.read(_boardFlippedProvider.notifier).state = !flipped,
          ),
          IconButton(
            icon: Icon(
              training ? Icons.visibility_off : Icons.visibility,
              color: training ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: training ? 'Switch to Learning' : 'Switch to Training',
            onPressed: () =>
                ref.read(_trainingModeProvider.notifier).state = !training,
          ),
          IconButton(
            icon: Icon(
              panelOpen ? Icons.analytics : Icons.analytics_outlined,
              color: panelOpen
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: panelOpen ? 'Hide panel' : 'Show analysis & moves',
            onPressed: () =>
                ref.read(_panelOpenProvider.notifier).state = !panelOpen,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          const Expanded(child: _BoardArea()),
          if (panelOpen)
            Container(
              width: _kSidePanel,
              decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: Colors.grey.shade300))),
              child: const _AnalysisPanel(),
            ),
        ],
      ),
        ),
      ),
    );
  }
}

// ── Mobile layout ─────────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerStatefulWidget {
  const _MobileLayout();

  @override
  ConsumerState<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<_MobileLayout> {
  bool _panelOpen = false;
  double _panelHeight = _kMinPanel;

  void _togglePanel() => setState(() => _panelOpen = !_panelOpen);

  void _onDrag(DragUpdateDetails d) {
    setState(() {
      _panelHeight =
          (_panelHeight - d.delta.dy).clamp(_kMinPanel, _kMaxPanel);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    // Snap closed if dragged down past minimum
    if (_panelHeight <= _kMinPanel + 20 && d.primaryVelocity != null && d.primaryVelocity! > 200) {
      setState(() => _panelOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(boardProvider);
    final opening = ref.watch(selectedOpeningProvider);
    final flipped = ref.watch(_boardFlippedProvider);
    final training = ref.watch(_trainingModeProvider);
    final canUndo =
        ref.watch(boardProvider.select((s) => s.moveHistory.isNotEmpty));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _AppBarTitle(
          name: opening?.name ?? 'Opening Trainer',
          variation: boardState.variation,
          status: boardState.status,
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Board fills all space not taken by the panel
          const Expanded(child: _BoardArea()),
          // Inline panel — pushes board up, never overlaps it
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _panelOpen
                ? GestureDetector(
                    onVerticalDragUpdate: _onDrag,
                    onVerticalDragEnd: _onDragEnd,
                    child: Container(
                      height: _panelHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade300)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const Expanded(child: _AnalysisPanel()),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border:
                Border(top: BorderSide(color: Colors.grey.shade300)),
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
                  Icons.swap_vert,
                  color: flipped
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Flip board',
                onPressed: () =>
                    ref.read(_boardFlippedProvider.notifier).state = !flipped,
              ),
              IconButton(
                icon: Icon(
                  training ? Icons.visibility_off : Icons.visibility,
                  color: training
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: training ? 'Switch to Learning' : 'Switch to Training',
                onPressed: () =>
                    ref.read(_trainingModeProvider.notifier).state = !training,
              ),
              IconButton(
                icon: Icon(
                  _panelOpen
                      ? Icons.analytics
                      : Icons.analytics_outlined,
                  color: _panelOpen
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: _panelOpen ? 'Hide analysis' : 'Show analysis',
                onPressed: _togglePanel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
