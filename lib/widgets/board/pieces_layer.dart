import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PiecesLayer extends StatelessWidget {
  final String fen;
  final double squareSize;
  final String? selectedSquare;
  final bool flipped;

  const PiecesLayer({
    super.key,
    required this.fen,
    required this.squareSize,
    this.selectedSquare,
    this.flipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = _parseFen(fen);
    return Stack(
      children: pieces.map((p) {
        final isSelected = _colRowToAlgebraic(p.col, p.row) == selectedSquare;
        final displayCol = flipped ? 7 - p.col : p.col;
        final displayRow = flipped ? 7 - p.row : p.row;
        return Positioned(
          left: displayCol * squareSize,
          top: displayRow * squareSize,
          width: squareSize,
          height: squareSize,
          child: Container(
            decoration: isSelected
                ? const BoxDecoration(
                    color: Color(0x66F6F669),
                  )
                : null,
            padding: EdgeInsets.all(squareSize * 0.04),
            child: SvgPicture.asset(
              'assets/pieces/${p.colorChar}${p.typeChar}.svg',
              width: squareSize,
              height: squareSize,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _colRowToAlgebraic(int col, int row) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }

  List<_PiecePos> _parseFen(String fen) {
    final boardFen = fen.split(' ')[0];
    final ranks = boardFen.split('/');
    final result = <_PiecePos>[];
    for (int row = 0; row < 8; row++) {
      int col = 0;
      for (final ch in ranks[row].runes) {
        final c = String.fromCharCode(ch);
        final n = int.tryParse(c);
        if (n != null) {
          col += n;
        } else {
          result.add(_PiecePos(
            col: col,
            row: row,
            colorChar: c == c.toUpperCase() ? 'w' : 'b',
            typeChar: c.toUpperCase(),
          ));
          col++;
        }
      }
    }
    return result;
  }
}

class _PiecePos {
  final int col, row;
  final String colorChar, typeChar;

  _PiecePos({
    required this.col,
    required this.row,
    required this.colorChar,
    required this.typeChar,
  });
}
