import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'retro.dart';

/// Panel biselado de la app. Con [title] muestra una cabecera tipo "01 / TÍTULO".
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.title,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final decoration = color != null
        ? BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: RetroStyle.edge, width: 1.4),
    )
        : RetroStyle.bevel(radius: 14);
    final body = Padding(padding: padding, child: child);
    return Container(
      width: double.infinity,
      decoration: decoration,
      child: title == null
          ? body
          : ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppColors.slate.withValues(alpha: 0.14),
              child: Row(
                children: [
                  const LedDot(size: 7),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title!.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: RetroStyle.mono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }
}

/// Título de sección estilo etiqueta: cuadro naranja + texto + línea.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10, top: 4),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 17, color: AppColors.orange)
          else
            Container(width: 9, height: 9, color: AppColors.orange),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 2, color: AppColors.silver.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}