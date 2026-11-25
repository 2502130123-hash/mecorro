/// Lectura combinada del acelerómetro y el giroscopio (se publica ~5 veces/seg).
class MotionData {
  const MotionData({
    this.intensity = 0,
    this.pitchDeg = 0,
    this.rollDeg = 0,
    this.gyroDegPerSec = 0,
    this.yawDeg = 0,
    this.turning = false,
    this.accelAvailable = true,
    this.gyroAvailable = true,
  });

  static const MotionData zero = MotionData();

  /// Aceleración dinámica suavizada (m/s² por encima/debajo de la gravedad).
  final double intensity;
  final double pitchDeg;
  final double rollDeg;

  /// Velocidad angular total en grados por segundo (giroscopio).
  final double gyroDegPerSec;

  /// Giro acumulado (0-360°) integrando el eje Z del giroscopio.
  final double yawDeg;
  final bool turning;
  final bool accelAvailable;
  final bool gyroAvailable;

  bool get isActive => intensity > 0.8;

  double get intensityLevel => (intensity / 5).clamp(0.0, 1.0).toDouble();

  String get intensityLabel {
    if (!accelAvailable) return 'No disponible';
    if (intensity < 0.8) return 'Reposo';
    if (intensity < 1.8) return 'Ligera';
    if (intensity < 3.5) return 'Moderada';
    return 'Alta';
  }
}