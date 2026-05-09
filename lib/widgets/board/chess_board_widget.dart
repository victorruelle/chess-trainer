import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/arrow.dart';
import '../../providers/board_provider.dart';
import 'board_painter.dart';
import 'pieces_layer.dart';
import 'arrows_painter.dart';

class ChessBoardWidget extends ConsumerWidget {
  final double boardSize;
  final List<Arrow> extraArrows;

  const ChessBoardWidget({
    super.key,
    required this.boardSize,
    this.extraArrows = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardState = ref.watch(boardProvider);
    final squareSize = boardSize / 8;
    final allArrows = [...boardState.arrows, ...extraArrows];

    return GestureDetector(
      onTapUp: (details) {
        final col = (details.localPosition.dx / squareSize).floor().clamp(0, 7);
        final row = (details.localPosition.dy / squareSize).floor().clamp(0, 7);
        ref.read(boardProvider.notifier).onSquareTapped(_toAlgebraic(col, row));
      },
      child: SizedBox(
        width: boardSize,
        height: boardSize,
        child: Stack(
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: Size(boardSize, boardSize),
                painter: BoardPainter(squareSize: squareSize),
              ),
            ),
            PiecesLayer(
              fen: boardState.fen,
              squareSize: squareSize,
              selectedSquare: boardState.selectedSquare,
            ),
            CustomPaint(
              size: Size(boardSize, boardSize),
              painter: ArrowsPainter(arrows: allArrows, squareSize: squareSize),
            ),
          ],
        ),
      ),
    );
  }

  String _toAlgebraic(int col, int row) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }
}
