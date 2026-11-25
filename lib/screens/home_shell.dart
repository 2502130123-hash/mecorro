import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/floating_nav_bar.dart';
import 'activity_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

/// Contenedor principal: nombre de la app arriba a la izquierda,
/// las 3 secciones en el centro y el menú flotante abajo.
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
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
            Positioned(
              left: 20,
              right: 20,
              bottom: 14 + bottomInset,
              child: const FloatingNavBar(),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(
        children: [
          const BrandMark(),
          const Spacer(),
          ListenableBuilder(
            listenable: ServiceLocator.session,
            builder: (context, _) {
              final name = ServiceLocator.session.currentUser?.displayName ?? '';
              final initial = name.isEmpty ? '?' : name[0].toUpperCase();
              return CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.slate,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}