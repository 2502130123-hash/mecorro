import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import 'retro.dart';

/// Menú flotante inferior (teclas biseladas): Actividad | Perfil | Historial.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  static const _items = <_NavItem>[
    _NavItem(Icons.directions_run_rounded, 'Actividad'),
    _NavItem(Icons.person_rounded, 'Perfil'),
    _NavItem(Icons.timeline_rounded, 'Historial'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ServiceLocator.tabIndex,
      builder: (context, index, _) {
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: RetroStyle.bevel(radius: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _items.length; i++)
                _NavButton(
                  item: _items[i],
                  selected: i == index,
                  onTap: () => ServiceLocator.tabIndex.value = i,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
            Icon(item.icon, size: 23, color: selected ? AppColors.white : AppColors.slate),
            if (selected) ...[
              const SizedBox(width: 7),
              Text(
                item.label.toUpperCase(),
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