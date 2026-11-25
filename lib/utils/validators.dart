import 'formatters.dart';

enum PasswordStrength { empty, weak, medium, strong }

/// Resultado de evaluar una contraseña (se calcula en vivo mientras se escribe).
class PasswordReport {
  const PasswordReport({
    required this.isEmpty,
    required this.minLength,
    required this.hasLetter,
    required this.hasDigit,
    required this.hasSpecial,
    required this.hasMixedCase,
    required this.isLong,
  });

  final bool isEmpty;
  final bool minLength; // >= 8 caracteres
  final bool hasLetter;
  final bool hasDigit;
  final bool hasSpecial;
  final bool hasMixedCase; // mayúsculas y minúsculas
  final bool isLong; // >= 12 caracteres

  /// Requisitos obligatorios: alfanumérica, >= 8 caracteres y con especiales.
  bool get meetsRequirements => minLength && hasLetter && hasDigit && hasSpecial;

  /// Semáforo: rojo (no cumple) / amarillo (cumple lo mínimo) / verde (fuerte).
  PasswordStrength get strength {
    if (isEmpty) return PasswordStrength.empty;
    if (!meetsRequirements) return PasswordStrength.weak;
    if (isLong && hasMixedCase) return PasswordStrength.strong;
    return PasswordStrength.medium;
  }
}

class PasswordValidator {
  PasswordValidator._();

  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9\s]');
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');

  static PasswordReport evaluate(String password) {
    return PasswordReport(
      isEmpty: password.isEmpty,
      minLength: password.length >= 8,
      hasLetter: _letter.hasMatch(password),
      hasDigit: _digit.hasMatch(password),
      hasSpecial: _special.hasMatch(password),
      hasMixedCase: _upper.hasMatch(password) && _lower.hasMatch(password),
      isLong: password.length >= 12,
    );
  }
}

/// Validadores para los TextFormField (devuelven null si todo está bien).
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

  static String? name(String? v) {
    if (v == null || v.trim().length < 3) return 'Escribe tu nombre completo';
    return null;
  }

  static String? email(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Escribe tu correo electrónico';
    if (!_email.hasMatch(text)) return 'Correo no válido (ej. nombre@correo.com)';
    return null;
  }

  static String? weight(String? v) {
    final n = Formatters.parseDouble(v);
    if (n == null) return 'Escribe tu peso en kg';
    if (n < 20 || n > 300) return 'Entre 20 y 300 kg';
    return null;
  }

  static String? height(String? v) {
    final n = Formatters.parseDouble(v);
    if (n == null) return 'Escribe tu estatura en cm';
    if (n < 80 || n > 250) return 'Entre 80 y 250 cm';
    return null;
  }

  static String? age(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Escribe tu edad';
    if (n < 10 || n > 110) return 'Entre 10 y 110 años';
    return null;
  }

  static String? password(String? v) {
    final report = PasswordValidator.evaluate(v ?? '');
    if (report.isEmpty) return 'Escribe una contraseña';
    if (!report.meetsRequirements) return 'No cumple todos los requisitos';
    return null;
  }

  static String? confirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
    if (v != original) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null;
}