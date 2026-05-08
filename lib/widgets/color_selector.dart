import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/opening_provider.dart';

class ColorSelector extends ConsumerWidget {
  const ColorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedColorProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Play as:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          _ColorChip(
            label: 'White',
            value: 'white',
            selected: selected == 'white',
            onTap: () => ref.read(selectedColorProvider.notifier).state = 'white',
          ),
          const SizedBox(width: 8),
          _ColorChip(
            label: 'Black',
            value: 'black',
            selected: selected == 'black',
            onTap: () => ref.read(selectedColorProvider.notifier).state = 'black',
          ),
          if (selected != null) ...[
            const SizedBox(width: 8),
            _ColorChip(
              label: 'All',
              value: null,
              selected: false,
              onTap: () => ref.read(selectedColorProvider.notifier).state = null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value == 'white')
              const _PieceIcon(isWhite: true)
            else if (value == 'black')
              const _PieceIcon(isWhite: false),
            if (value != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieceIcon extends StatelessWidget {
  final bool isWhite;
  const _PieceIcon({required this.isWhite});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isWhite ? Colors.white : Colors.black87,
        border: Border.all(color: Colors.grey.shade600, width: 1.5),
      ),
    );
  }
}
