/// Acumulado de un día (pasos, calorías y distancia). Es mutable a propósito:
/// el WorkoutController lo va incrementando en tiempo real.
class DailyStats {
  DailyStats({this.steps = 0, this.calories = 0, this.distanceM = 0});

  int steps;
  double calories;
  double distanceM;

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'calories': calories,
    'distanceM': distanceM,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    calories: (json['calories'] as num?)?.toDouble() ?? 0,
    distanceM: (json['distanceM'] as num?)?.toDouble() ?? 0,
  );
}

/// Barra de la gráfica de los últimos 7 días.
class DayBar {
  const DayBar({required this.date, required this.steps});

  final DateTime date;
  final int steps;
}