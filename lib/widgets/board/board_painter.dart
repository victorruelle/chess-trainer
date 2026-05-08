import 'package:flutter/material.dart';

class BoardPainter extends CustomPainter {
  final double squareSize;
  static const _light = Color(0xFFF0D9B5);
  static const _dark = Color(0xFFB58863);

  const BoardPainter({required this.squareSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final isLight = (row + col) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(
            col * squareSize,
            row * squareSize,
            squareSize,
            squareSize,
          ),
          Paint()..color = isLight ? _light : _dark,
        );
      }
    }
    _drawCoordinates(canvas);
  }

  void _drawCoordinates(Canvas canvas) {
    final textStyle = TextStyle(
      fontSize: squareSize * 0.18,
      fontWeight: FontWeight.bold,
    );
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (int col = 0; col < 8; col++) {
      final isLight = (7 + col) % 2 == 0;
      final tp = TextPainter(
        text: TextSpan(
          text: files[col],
          style: textStyle.copyWith(color: isLight ? _dark : _light),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          col * squareSize + squareSize - tp.width - squareSize * 0.05,
          7 * squareSize + squareSize - tp.height - squareSize * 0.05,
        ),
      );
    }
    for (int row = 0; row < 8; row++) {
      final isLight = (row + 0) % 2 == 0;
      final tp = TextPainter(
        text: TextSpan(
          text: '${8 - row}',
          style: textStyle.copyWith(color: isLight ? _dark : _light),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(squareSize * 0.05, row * squareSize + squareSize * 0.05),
      );
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) => false;
}
