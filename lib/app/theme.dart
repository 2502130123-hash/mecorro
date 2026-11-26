import 'package:flutter/material.dart';

/// Paleta oficial de mecorro (la que elegiste en Coolors).
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF2D3142); // 2D3142
  static const Color silver = Color(0xFFBFC0C0); // BFC0C0
  static const Color white = Color(0xFFFFFFFF); // FFFFFF
  static const Color orange = Color(0xFFEF8354); // EF8354
  static const Color slate = Color(0xFF4F5D75); // 4F5D75

  // Colores semánticos (semáforo de contraseña, IMC, errores)
  static const Color danger = Color(0xFFD64545);
  static const Color warning = Color(0xFFF2B134);
  static const Color success = Color(0xFF3FA66B);

  /// Fondo de tarjetas (gris plata muy suave).
  static Color get card => silver.withValues(alpha: 0.2);
  static Color get softShadow => navy.withValues(alpha: 0.16);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.orange,
      onPrimary: AppColors.white,
      secondary: AppColors.slate,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.navy,
      error: AppColors.danger,
      onError: AppColors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navy,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),
    );
  }
}

/// Estilos reutilizables (campos de texto y botones) con aspecto retro.
class AppDecor {
  AppDecor._();

  static InputDecoration input({
    required String label,
    IconData? icon,
    Widget? suffix,
    String? hint,
    String? suffixText,
  }) {
    OutlineInputBorder border(Color color, [double width = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.slate),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.white,
      labelStyle: const TextStyle(color: AppColors.slate),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: border(AppColors.silver),
      enabledBorder: border(AppColors.silver),
      focusedBorder: border(AppColors.orange, 2),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 2),
    );
  }

  static ButtonStyle primaryButton({Color color = AppColors.orange}) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: AppColors.white,
      minimumSize: const Size.fromHeight(54),
      elevation: 3,
      shadowColor: AppColors.navy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.navy.withValues(alpha: 0.55), width: 1.4),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  static ButtonStyle outlineButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.navy,
      backgroundColor: AppColors.white,
      minimumSize: const Size.fromHeight(54),
      side: const BorderSide(color: AppColors.slate, width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
    );
  }
}