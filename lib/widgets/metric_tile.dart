import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'app_card.dart';
import 'retro.dart';

/// Métrica en una pantalla LCD: icono, número luminoso y etiqueta con LED.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lcdColor = color == AppColors.orange ? AppColors.orange : AppColors.white;
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: LcdScreen(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: lcdColor, size: 20),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: value,
                            style: TextStyle(
                              fontFamily: RetroStyle.mono,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: lcdColor,
                            ),
                          ),
                          if (unit.isNotEmpty)
                            const TextSpan(text: ' '),
                          if (unit.isNotEmpty)
                            TextSpan(
                              text: unit,
                              style: const TextStyle(
                                fontFamily: RetroStyle.mono,
                                fontSize: 12,
                                color: AppColors.silver,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LedDot(
                color: lcdColor == AppColors.orange ? AppColors.orange : AppColors.slate,
                size: 7,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}