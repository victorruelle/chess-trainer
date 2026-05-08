import 'package:flutter/material.dart';
import '../services/stockfish_service.dart';

class EvalBar extends StatelessWidget {
  final EngineEval? eval;
  final double height;

  const EvalBar({
    super.key,
    this.eval,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (eval == null) {
      return SizedBox(
        width: 24,
        height: height,
        child: Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Calculate proportions: eval > 0 = White winning, eval < 0 = Black winning
    // Clamp to -10 to +10 for visual purposes
    final clampedEval = eval!.score.clamp(-10.0, 10.0);
    final midpoint = (10 + clampedEval) / 20; // 0 to 1, where 0.5 is equal

    return SizedBox(
      width: 24,
      height: height,
      child: Stack(
        children: [
          // White section (top)
          Container(
            height: height * midpoint,
            color: Colors.white,
            child: const SizedBox.expand(),
          ),
          // Black section (bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: height * (1 - midpoint),
            child: Container(
              color: Colors.grey.shade800,
            ),
          ),
          // Border
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
          ),
          // Score and depth text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eval.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  'd${eval!.depth}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black45,
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
