import '../models/activity_mode.dart';

enum BmiCategory { underweight, normal, overweight, obese }

/// Fórmulas de salud y deporte (IMC, metabolismo basal, zancada, MET).
class HealthCalculator {
  HealthCalculator._();

  /// IMC = peso(kg) / estatura(m)^2
  static double bmi(double weightKg, double heightCm) {
    final m = heightCm / 100;
    if (m <= 0) return 0;
    return weightKg / (m * m);
  }

  static BmiCategory bmiCategory(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  static String bmiLabel(BmiCategory c) => switch (c) {
    BmiCategory.underweight => 'Bajo peso',
    BmiCategory.normal => 'Peso normal',
    BmiCategory.overweight => 'Sobrepeso',
    BmiCategory.obese => 'Obesidad',
  };

  /// Metabolismo basal (Mifflin-St Jeor) en kcal/día.
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    switch (gender) {
      case 'Masculino':
        return base + 5;
      case 'Femenino':
        return base - 161;
      default:
        return base - 78;
    }
  }

  /// Longitud de zancada estimada a partir de la estatura (en metros).
  static double strideLengthM({
    required double heightCm,
    required String gender,
    required ActivityMode mode,
  }) {
    final factor = gender == 'Femenino' ? 0.413 : 0.415;
    final walking = heightCm * factor / 100;
    return mode == ActivityMode.running ? walking * 1.35 : walking;
  }

  /// Calorías por paso fuera de un entrenamiento (~0.7 kcal por kg y por km).
  static double caloriesPerStep(double weightKg, double strideM) =>
      0.7 * weightKg * strideM / 1000;

  /// MET (equivalente metabólico) según actividad y velocidad (km/h).
  /// Calorías = MET * peso(kg) * horas.
  static double met(ActivityMode mode, double speedKmh) {
    if (speedKmh < 0.5) return 1.3; // casi en reposo
    switch (mode) {
      case ActivityMode.walking:
        if (speedKmh < 3.2) return 2.8;
        if (speedKmh < 4.0) return 3.0;
        if (speedKmh < 4.8) return 3.5;
        if (speedKmh < 5.6) return 4.3;
        if (speedKmh < 6.4) return 5.0;
        return 7.0;
      case ActivityMode.running:
        final v = speedKmh * 1.0;
        if (v < 6.0) return 6.0;
        if (v > 18.0) return 18.0;
        return v;
      case ActivityMode.cycling:
        if (speedKmh < 16) return 4.0;
        if (speedKmh < 19.2) return 6.8;
        if (speedKmh < 22.4) return 8.0;
        if (speedKmh < 25.6) return 10.0;
        if (speedKmh < 30.6) return 12.0;
        return 15.8;
    }
  }
}