import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_colors.dart';

class ServeProgressIndicator extends StatelessWidget {
  final int current; // numéro du service en cours (1..10)
  final int total;

  const ServeProgressIndicator({super.key, required this.current, this.total = kServesPerSession});

  @override
  Widget build(BuildContext context) {
    final ratio = (current / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service $current / $total',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
