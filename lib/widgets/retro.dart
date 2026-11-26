import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Piezas del estilo "retro / Y2K": ventanas biseladas, pantallas LCD y fondo cuadriculado.
class RetroStyle {
  RetroStyle._();

  static const String mono = 'monospace';

  /// Imagen del tigre (declarada en pubspec.yaml -> assets).
  static const String tigerAsset = 'assets/icon/tige.jpeg';

  static Color get panelLight => Color.lerp(AppColors.white, AppColors.silver, 0.30)!;
  static Color get panelDark => Color.lerp(AppColors.white, AppColors.silver, 0.65)!;
  static Color get edge => AppColors.slate.withValues(alpha: 0.55);

  /// Panel biselado: degradado suave, borde marcado y sombra dura (sin difuminar).
  static BoxDecoration bevel({double radius = 14, bool shadow = true}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.white, panelLight],
      ),
      border: Border.all(color: edge, width: 1.4),
      boxShadow: shadow
          ? [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.30),
          offset: const Offset(0, 3),
          blurRadius: 0,
        ),
      ]
          : null,
    );
  }
}

/// Foco LED con brillo.
class LedDot extends StatelessWidget {
  const LedDot({super.key, this.color = AppColors.orange, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 5)],
      ),
    );
  }
}

/// Imagen del tigre (tige.jpeg). Si el archivo no está en assets, muestra un icono.
class TigerImage extends StatelessWidget {
  const TigerImage({super.key, required this.size, this.circle = false});

  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      RetroStyle.tigerAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: size,
        height: size,
        color: AppColors.navy,
        child: Icon(Icons.directions_run_rounded, color: AppColors.orange, size: size * 0.6),
      ),
    );
    return circle ? ClipOval(child: image) : image;
  }
}

/// Fondo azul marino con cuadrícula fina.
class GridBackground extends StatelessWidget {
  const GridBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navy,
      child: SizedBox.expand(
        child: CustomPaint(painter: _GridPainter(), child: child),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = AppColors.slate.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    final bold = Paint()
      ..color = AppColors.slate.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    const step = 28.0;
    var i = 0;
    for (double x = 0; x <= size.width; x += step, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 4 == 0 ? bold : thin);
    }
    i = 0;
    for (double y = 0; y <= size.height; y += step, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 4 == 0 ? bold : thin);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pantalla LCD: fondo azul marino, marco gris y líneas de barrido.
class LcdScreen extends StatelessWidget {
  const LcdScreen({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 10,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.slate, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: CustomPaint(
          foregroundPainter: _ScanlinePainter(),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ventana con barra de título (como la página central de la imagen de referencia).
class RetroWindow extends StatelessWidget {
  const RetroWindow({
    super.key,
    required this.title,
    required this.child,
    this.expand = false,
  });

  final String title;
  final Widget child;

  /// true: ocupa todo el alto disponible (el hijo va dentro de un Expanded).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: RetroStyle.bevel(radius: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _TitleBar(title: title),
            if (expand) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RetroStyle.panelLight, RetroStyle.panelDark],
        ),
        border: Border(bottom: BorderSide(color: RetroStyle.edge, width: 1.2)),
      ),
      child: Row(
        children: [
          const LedDot(color: AppColors.orange, size: 8),
          const SizedBox(width: 6),
          const LedDot(color: AppColors.silver, size: 8),
          const SizedBox(width: 6),
          const LedDot(color: AppColors.slate, size: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: RetroStyle.mono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: AppColors.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Página de autenticación: fondo cuadriculado + ventana centrada con scroll.
class RetroPage extends StatelessWidget {
  const RetroPage({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: GridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(12),
            child: RetroWindow(title: title, child: child),
          ),
        ),
      ),
    );
  }
}