import 'package:flutter_test/flutter_test.dart';
import 'package:mecorro/models/activity_mode.dart';
import 'package:mecorro/services/security_service.dart';
import 'package:mecorro/utils/health_calculator.dart';
import 'package:mecorro/utils/validators.dart';

void main() {
  group('IMC', () {
    test('calcula el IMC con peso y estatura', () {
      expect(HealthCalculator.bmi(70, 175), closeTo(22.86, 0.01));
    });

    test('clasifica las categorías', () {
      expect(HealthCalculator.bmiCategory(17), BmiCategory.underweight);
      expect(HealthCalculator.bmiCategory(22), BmiCategory.normal);
      expect(HealthCalculator.bmiCategory(27), BmiCategory.overweight);
      expect(HealthCalculator.bmiCategory(32), BmiCategory.obese);
    });
  });

  group('Contraseña', () {
    test('débil si no cumple requisitos', () {
      expect(PasswordValidator.evaluate('abc').strength, PasswordStrength.weak);
      expect(PasswordValidator.evaluate('abcdefgh').strength, PasswordStrength.weak);
    });

    test('aceptable si cumple lo mínimo', () {
      expect(PasswordValidator.evaluate('abc123!x').strength, PasswordStrength.medium);
    });

    test('segura con 12+ caracteres y mayúsculas/minúsculas', () {
      expect(PasswordValidator.evaluate('Abc12345!xyz').strength, PasswordStrength.strong);
    });
  });

  group('Seguridad', () {
    test('el hash coincide solo con la contraseña correcta', () {
      final salt = SecurityService.generateSalt();
      final hash = SecurityService.hashPassword('Secreta#123', salt);
      expect(SecurityService.verify('Secreta#123', salt, hash), isTrue);
      expect(SecurityService.verify('otra', salt, hash), isFalse);
    });
  });

  group('Calorías', () {
    test('correr quema más que caminar a la misma duración', () {
      final walk = HealthCalculator.met(ActivityMode.walking, 5);
      final run = HealthCalculator.met(ActivityMode.running, 10);
      expect(run, greaterThan(walk));
    });
  });
}