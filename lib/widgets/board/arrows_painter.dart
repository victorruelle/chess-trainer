import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/arrow.dart';

class ArrowsPainter extends CustomPainter {
  final List<Arrow> arrows;
  final double squareSize;
  final bool flipped;

  const ArrowsPainter({
    required this.arrows,
    required this.squareSize,
    this.flipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in reverse rank order so gold renders on top
    final sorted = [...arrows]
      ..sort((a, b) => b.rank.index.compareTo(a.rank.index));
    for (final arrow in sorted) {
      _drawArrow(canvas, arrow);
    }
  }

  void _drawArrow(Canvas canvas, Arrow arrow) {
    final from = _squareCenter(arrow.fromSquare);
    final to = _squareCenter(arrow.toSquare);

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final dirX = dx / length;
    final dirY = dy / length;
    final perpX = -dirY;
    final perpY = dirX;

    final headLen = squareSize * 0.38;
    final halfBase = squareSize * 0.22;
    final shaftWidth = squareSize * 0.15;

    final shaftEndX = to.dx - dirX * headLen;
    final shaftEndY = to.dy - dirY * headLen;

    // Shorten start so arrow doesn't start in piece center
    final startX = from.dx + dirX * squareSize * 0.3;
    final startY = from.dy + dirY * squareSize * 0.3;

    final color = arrow.rank.color.withValues(alpha: arrow.rank.opacity);
    final paint = Paint()
      ..color = color
      ..strokeWidth = shaftWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(shaftEndX, shaftEndY),
      paint,
    );

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(shaftEndX + perpX * halfBase, shaftEndY + perpY * halfBase)
      ..lineTo(shaftEndX - perpX * halfBase, shaftEndY - perpY * halfBase)
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  Offset _squareCenter(String sq) {
    var col = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    var row = 8 - int.parse(sq[1]);
    if (flipped) {
      col = 7 - col;
      row = 7 - row;
    }
    return Offset(
      col * squareSize + squareSize / 2,
      row * squareSize + squareSize / 2,
    );
  }

  @override
  bool shouldRepaint(ArrowsPainter old) =>
      old.arrows != arrows || old.squareSize != squareSize || old.flipped != flipped;
}
