import 'dart:math';
import 'package:flutter/material.dart';
import '../services/stockfish_service.dart';

class EvalBar extends StatelessWidget {
  final EngineEval? eval;
  final bool isReady;

  const EvalBar({super.key, this.eval, this.isReady = false});

  /// Maps engine score (pawns) to a 0–1 fraction for the white portion.
  /// Uses tanh so +5 ≈ 87%, -5 ≈ 13%, 0 = 50%.  Mirrors Lichess's bar scale.
  double _whiteFraction(double score) {
    final s = score.clamp(-15.0, 15.0);
    return 0.5 + 0.5 * (2 / pi) * atan(s / 3.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;

      return SizedBox(
        width: 22,
        height: height,
        child: Column(
          children: [
            // Score label at very top
            _ScoreLabel(eval: eval),
            // The bar itself
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: _buildBar(height - 24),
              ),
            ),
            // Depth label at bottom
            _DepthLabel(eval: eval, isReady: isReady),
          ],
        ),
      );
    });
  }

  Widget _buildBar(double height) {
    if (!isReady || eval == null) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }

    final whiteFrac = _whiteFraction(eval!.score);

    return Stack(
      children: [
        // Black fills everything
        Container(color: const Color(0xFF2C2C2C)),
        // White fills from the top
        FractionallySizedBox(
          alignment: Alignment.topCenter,
          heightFactor: whiteFrac,
          child: Container(color: Colors.white),
        ),
        // Centre line
        Align(
          alignment: const Alignment(0, 0),
          child: Container(height: 1, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _ScoreLabel extends StatelessWidget {
  final EngineEval? eval;
  const _ScoreLabel({this.eval});

  @override
  Widget build(BuildContext context) {
    final text = eval?.display ?? '…';
    return SizedBox(
      height: 18,
      child: FittedBox(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _DepthLabel extends StatelessWidget {
  final EngineEval? eval;
  final bool isReady;
  const _DepthLabel({this.eval, required this.isReady});

  @override
  Widget build(BuildContext context) {
    final text = eval != null ? 'd${eval!.depth}' : (isReady ? 'd—' : '…');
    return SizedBox(
      height: 16,
      child: FittedBox(
        child: Text(
          text,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
