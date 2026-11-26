import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/retro.dart';
import 'activity_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

/// Contenedor principal: ventana retro sobre fondo cuadriculado, con el nombre de la app
/// arriba a la izquierda, las 3 secciones en el centro y el menú flotante abajo.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  // Pantallas const: nunca se recrean, así conservan su estado dentro del IndexedStack.
  static const List<Widget> _pages = [
    ActivityScreen(),
    ProfileScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: GridBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10 + bottomInset),
                  child: RetroWindow(
                    title: 'mecorro / estación personal',
                    expand: true,
                    child: Column(
                      children: [
                        const _TopBar(),
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: ServiceLocator.tabIndex,
                            builder: (context, index, _) =>
                                IndexedStack(index: index, children: _pages),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 22 + bottomInset,
                child: const FloatingNavBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          const BrandMark(),
          const Spacer(),
          ListenableBuilder(
            listenable: ServiceLocator.session,
            builder: (context, _) {
              final name = ServiceLocator.session.currentUser?.displayName ?? '';
              return LcdScreen(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                radius: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LedDot(size: 6),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: RetroStyle.mono,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}