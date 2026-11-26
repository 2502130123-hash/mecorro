import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'retro.dart';

/// Tigre + nombre "mecorro" (esquina superior de la app).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.size = 22});

  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.navy,
            border: Border.all(color: AppColors.orange, width: 2),
          ),
          child: TigerImage(size: size * 1.4, circle: true),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'me',
                style: TextStyle(color: onDark ? AppColors.white : AppColors.navy),
              ),
              const TextSpan(text: 'corro', style: TextStyle(color: AppColors.orange)),
            ],
          ),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}