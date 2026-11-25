import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Logo + nombre "mecorro" (esquina superior de la app).
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
          width: size * 1.5,
          height: size * 1.5,
          decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
          child: Icon(Icons.directions_run_rounded, color: AppColors.white, size: size),
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
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}