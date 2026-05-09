import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/opening.dart';
import '../providers/progress_provider.dart';
import '../screens/board_screen.dart' show StarRating;

class OpeningCard extends ConsumerWidget {
  final Opening opening;
  final VoidCallback onTap;

  const OpeningCard({super.key, required this.opening, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ref.watch(starsForOpeningProvider(opening.id));
    final isWhite = opening.color == 'white';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWhite ? Colors.white : Colors.black87,
                  border:
                      Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: Icon(
                  Icons.sports_esports_outlined,
                  size: 18,
                  color: isWhite ? Colors.black87 : Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opening.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'ECO ${opening.eco} · ${isWhite ? "White" : "Black"}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (stars > 0) ...[
                          const SizedBox(width: 8),
                          StarRating(stars: stars, size: 12),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
