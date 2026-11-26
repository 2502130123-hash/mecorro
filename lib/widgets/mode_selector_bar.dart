import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../models/activity_mode.dart';
import 'retro.dart';

/// Menú flotante superior: muestra con iconos el modo seleccionado
/// (caminata / correr / ciclismo) y también permite tocarlos.
class ModeSelectorBar extends StatelessWidget {
  const ModeSelectorBar({super.key});

  @override
  Widget build(BuildContext context) {
    final workout = ServiceLocator.workout;
    return ListenableBuilder(
      listenable: workout,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: RetroStyle.bevel(radius: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in ActivityMode.values)
                _ModeChip(mode: m, selected: m == workout.mode),
            ],
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode, required this.selected});

  final ActivityMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final controller = ServiceLocator.modePageController;
        if (controller.hasClients) {
          controller.animateToPage(
            mode.index,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? AppColors.navy.withValues(alpha: 0.55) : Colors.transparent,
            width: 1.4,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.35),
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 23, color: selected ? AppColors.white : AppColors.slate),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                mode.label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}