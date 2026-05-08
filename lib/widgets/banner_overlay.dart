import 'package:flutter/material.dart';
import '../models/opening_status.dart';

class BannerOverlay extends StatelessWidget {
  final OpeningStatus status;
  final String openingName;

  const BannerOverlay({
    super.key,
    required this.status,
    required this.openingName,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      OpeningStatus.inBook => const SizedBox.shrink(),
      OpeningStatus.offBook => _Banner(
          message: "You've left the $openingName opening",
          backgroundColor: Colors.orange.shade100,
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orange.shade700,
        ),
      OpeningStatus.complete => _Banner(
          message: '$openingName complete — keep playing!',
          backgroundColor: Colors.green.shade100,
          icon: Icons.check_circle_outline,
          iconColor: Colors.green.shade700,
        ),
    };
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  const _Banner({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
