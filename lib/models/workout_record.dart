/// Entrenamiento terminado (se guarda en el historial local).
class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.date,
    required this.mode,
    required this.durationSec,
    required this.steps,
    required this.distanceM,
    required this.calories,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
  });

  final String id;
  final DateTime date;

  /// Nombre del enum ActivityMode (walking | running | cycling).
  final String mode;
  final int durationSec;
  final int steps;
  final double distanceM;
  final double calories;
  final double avgSpeedKmh;
  final double maxSpeedKmh;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'mode': mode,
    'durationSec': durationSec,
    'steps': steps,
    'distanceM': distanceM,
    'calories': calories,
    'avgSpeedKmh': avgSpeedKmh,
    'maxSpeedKmh': maxSpeedKmh,
  };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
    id: json['id'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    mode: json['mode'] as String? ?? 'walking',
    durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    distanceM: (json['distanceM'] as num?)?.toDouble() ?? 0,
    calories: (json['calories'] as num?)?.toDouble() ?? 0,
    avgSpeedKmh: (json['avgSpeedKmh'] as num?)?.toDouble() ?? 0,
    maxSpeedKmh: (json['maxSpeedKmh'] as num?)?.toDouble() ?? 0,
  );
}