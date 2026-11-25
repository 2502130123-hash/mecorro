import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../utils/validators.dart';

/// Semáforo de seguridad de la contraseña + lista de requisitos en vivo.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.report});

  final PasswordReport report;

  Color get _color => switch (report.strength) {
    PasswordStrength.empty => AppColors.silver,
    PasswordStrength.weak => AppColors.danger,
    PasswordStrength.medium => AppColors.warning,
    PasswordStrength.strong => AppColors.success,
  };

  String get _label => switch (report.strength) {
    PasswordStrength.empty => 'Escribe una contraseña',
    PasswordStrength.weak => 'Débil (rojo)',
    PasswordStrength.medium => 'Aceptable (amarillo)',
    PasswordStrength.strong => 'Segura (verde)',
  };

  int get _level => switch (report.strength) {
    PasswordStrength.empty => 0,
    PasswordStrength.weak => 1,
    PasswordStrength.medium => 2,
    PasswordStrength.strong => 3,
  };

  @override
  Widget build(BuildContext context) {
    // Rojo / amarillo / verde: cada tramo se enciende con su propio color
    const colors = [AppColors.danger, AppColors.warning, AppColors.success];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < _level ? colors[i] : AppColors.silver.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 18, color: _color),
            const SizedBox(width: 6),
            Text(
              _label,
              style: TextStyle(fontWeight: FontWeight.w700, color: _color, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Rule(ok: report.minLength, text: 'Mínimo 8 caracteres'),
        _Rule(ok: report.hasLetter, text: 'Contiene letras'),
        _Rule(ok: report.hasDigit, text: 'Contiene números'),
        _Rule(ok: report.hasSpecial, text: 'Contiene un carácter especial (! @ # \$ % & *)'),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 17,
            color: ok ? AppColors.success : AppColors.silver,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: ok ? AppColors.navy : AppColors.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}