import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../models/activity_mode.dart';

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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.silver.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.softShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 24, color: selected ? AppColors.white : AppColors.slate),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                mode.label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}